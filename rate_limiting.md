# Rate Limiting and Retry Handling Design Note - Keen IO iOS SDK

## Overview and Scope

The Keen IO API enforces rate limits on ad-hoc queries, extractions, and deletions. This is described here [https://keen.io/docs/api/#limits]()

Clients need to be equipped to properly handle when they have reached Keen IO's API rate limits, or have reached the capacity for servers to handle ad-hoc query requests.

Of the rate-limited API features, the iOS SDK only enables ad-hoc queries and so is only concerned with those requests.

An ad-hoc query is defined as a single-analysis, multi-analysis, funnel, or saved query request.

## Description of existing implementation
Single-analysis and funnel query API requests through the iOS SDK store a 400-series failure count mapped from the query description json. If a request fails 10 times within a 3600 second (1 hour) window starting at the time of the first failure, further single-analysis or funnel API requests through the SDK are ignored by the SDK until the 3600 second window passes, and then the failure account for that specific query are reset and requests continue.

#### Shortcomings of this approach
* Rate-limited failures are stored per query, not per project. Rate limits are defined on a project level according to documentation [https://keen.io/docs/api/#limits]().
* Multi-analysis rate-limiting isn't handled.
* Ad-hoc queries are limited to 100/minute, which has no real correlation to disallowing queries for a duration of 1 hour.
* If a request is rate limited, allowing retries 9 times before denying a new attempt is excessive
* 503 Service Unavailable errors aren't handled. Although a different error, would require a similar type of reduction in requests from clients
* 400-series errors other than 429's are treated as something to be rate-limited. Is that the correct approach? [Open item #1](#open-items)
* Client code receives no callback from the SDK when requests are being ignored, and so has no way of managing retry logic.
* Denying client requests by this mechanism does nothing to handle client contention, and nothing to alleviate request-per-minute when many clients are making requests since delay is constant.




## Proposal

All ad-hoc query requests for a project should be delayed by the client when a 429 or 503 response has been received for the last ad-hoc query attempt for that project. The delay should be derived from the number of prior failures of requests using an exponential backoff with random jitter [1]. This delay will reduce request load over time and allow client requests to be handled in as timely a manner as possible without a large amount of contention, which further would slow request handling.

When receiving an ad-hoc query response:
* 429 Too Many Request HTTP responses are recorded in the database with a time stamp. Data recorded will include: project id, time of last failure, and failure count.
* 503 Service Unavailable responses are also recorded with a time stamp.
    * Possibly in their own table, or in the same table as 429 failures with project ids [Open item #2](#open-items)

When making an ad-hoc query request:
* Look up response failures for the project referenced, prioritizing 503 codes. If failures exist, delay performing the request until a calculated duration from the most recent failure, unless that delay has already elapsed. This delay will not require further code in clients, but will manifest only as a delay in receiving the request completion callback.
    * Delay from attempts should be calculated as `delay = random_between(0, min(max_delay, base_delay * 2^(previous_failures - 1)))`
        * See [1] for a discussion on this algorithm, described as "Full Jitter" in the linked text.
        * This calculation includes an exponential backoff along with jitter. Exponential backoff reduces the number of attempts among clients over time as failures continue, while random jitter reduces contention between clients.
        * According to API documentation, rate limits are given per-minute. Upon confirming that this is the case, it would then make sense to perform a retry no sooner than something on the order of 30 seconds on average, so perhaps a `base_delay` of 30 seconds could make sense at least for 429's.
            * [Open item #3](#open-items)
* Successful ad-hoc query responses will clear failure counts for the corresponding project.



#### Open Items
1. Should 400-series errors other than 429's be handled as something to be rate-limited on a project level? Or should something else be done for these errors? Or should nothing be done?

2. Should 503 responses be stored along with 429 errors, including project ids, or should they be stored without project information and impact all ad-hoc queries for any project?

3. Is the same type of delay acceptable for 503 failures?

4. Will a Retry-After response header be included with 429 or 503 responses? [https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After]()

5. Should SDK clients be given control over retry parameters like base delay?

6. Should SDK clients be able notified that a request is going to be delayed? Should they be able to abort instead of making the request after a delay?

##### References
[1] [https://www.awsarchitectureblog.com/2015/03/backoff.html]()

