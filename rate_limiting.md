# Rate Limiting and Retry Handling Design Note


## Description of existing implementation
Single-analysis and funnel query API requests through the iOS SDK store a 400-series failure count mapped from the query description json. If a request fails 10 times within a 3600 (1 hour) second window starting at the time of the first failure, further single-analysis or funnel API requests through the SDK are ignored by the SDK until the 3600 second window passes, and then the failure account for that specific query are reset and requests continue.

#### Shortcomings of this approach
* Rate-limited failures are stored per query, not per project. Rate limits are defined on a project level according to documentation [https://keen.io/docs/api/#limits]().
* Multi-analysis rate-limiting isn't handled.
* Ad-hoc queries are limited to 100/minute, which has no real correlation to disallowing queries for a duration of 1 hour.
* If a request is rate limited, allowing retries 9 times before denying a new attempt is excessive
* 503 Service Unavailable errors aren't handled. Although a different error, would require a similar type of reduction in requests from clients

#### Proposal
When receiving an ad-hoc query response:
* 429 Too Many Request HTTP responses are recorded in the database with a time stamp. Data recorded will include: project id, time of last failure, and failure count.
* 503 Service Unavailable responses are also recorded with a time stamp.
    * [Open item #1](#open-items)

When making an ad-hoc query request:
* Look up response failures for the project referenced, prioritizing 503 codes. If failures exist, delay performing the request until a calculated duration from the most recent failure, unless that delay has already elapsed. This delay will not require further code in clients, but will manifest only as a delay in receiving the request completion callback.
    * Delay from attempts should be calculated as `delay = random_between(0, min(max_delay, base_delay * 2^(previous_failures - 1)))`
        * See [1] for a discussion on this algorithm, described as "Full Jitter" in the linked text.
        * This calculation includes an exponential backoff along with jitter. Exponential backoff reduces the number of attempts among clients over time as failures continue, while random jitter reduces contention between clients.
        * According to API documentation, rate limits are given per-minute, which presumably means they are metered per-minute. Upon confirming that this is the case, it would then make sense to perform a retry no sooner than something on the order of 30 seconds on average, so perhaps a `base_delay` of 30 seconds could make sense at least for 429's.
            * [Open item #2](#open-items)
* Successful ad-hoc query responses will clear failure counts for the corresponding project.

#### Open Items
1. Should 503 responses be stored along with 429 errors, including project ids, or should they be stored without project information and impact all ad-hoc queries for any project?

2. Is the same type of delay acceptable for 503 failures?

##### References
[1] [https://www.awsarchitectureblog.com/2015/03/backoff.html]()

