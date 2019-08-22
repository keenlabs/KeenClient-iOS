// Namespaced Header

#ifndef __NS_SYMBOL
// We need to have multiple levels of macros here so that __NAMESPACE_PREFIX_ is
// properly replaced by the time we concatenate the namespace prefix.
#define __NS_REWRITE(ns, symbol) ns ## _ ## symbol
#define __NS_BRIDGE(ns, symbol) __NS_REWRITE(ns, symbol)
#define __NS_SYMBOL(symbol) __NS_BRIDGE(MR, symbol)
#endif


// Classes
#ifndef HTTPCodes
#define HTTPCodes __NS_SYMBOL(HTTPCodes)
#endif

#ifndef KIODBStore
#define KIODBStore __NS_SYMBOL(KIODBStore)
#endif

#ifndef KIODefaultNSURLSessionFactory
#define KIODefaultNSURLSessionFactory __NS_SYMBOL(KIODefaultNSURLSessionFactory)
#endif

#ifndef KIOFileStore
#define KIOFileStore __NS_SYMBOL(KIOFileStore)
#endif

#ifndef KIONetwork
#define KIONetwork __NS_SYMBOL(KIONetwork)
#endif

#ifndef KIOQuery
#define KIOQuery __NS_SYMBOL(KIOQuery)
#endif

#ifndef KIOReachability
#define KIOReachability __NS_SYMBOL(KIOReachability)
#endif

#ifndef KIOUploader
#define KIOUploader __NS_SYMBOL(KIOUploader)
#endif

#ifndef KIOUtil
#define KIOUtil __NS_SYMBOL(KIOUtil)
#endif

#ifndef KeenClient
#define KeenClient __NS_SYMBOL(KeenClient)
#endif

#ifndef KeenClientConfig
#define KeenClientConfig __NS_SYMBOL(KeenClientConfig)
#endif

#ifndef KeenLogSinkNSLog
#define KeenLogSinkNSLog __NS_SYMBOL(KeenLogSinkNSLog)
#endif

#ifndef KeenLogger
#define KeenLogger __NS_SYMBOL(KeenLogger)
#endif

#ifndef KeenProperties
#define KeenProperties __NS_SYMBOL(KeenProperties)
#endif

// Functions
#ifndef keen_io_sqlite3_compileoption_used
#define keen_io_sqlite3_compileoption_used __NS_SYMBOL(keen_io_sqlite3_compileoption_used)
#endif

#ifndef keen_io_sqlite3_strnicmp
#define keen_io_sqlite3_strnicmp __NS_SYMBOL(keen_io_sqlite3_strnicmp)
#endif

#ifndef keen_io_sqlite3_compileoption_get
#define keen_io_sqlite3_compileoption_get __NS_SYMBOL(keen_io_sqlite3_compileoption_get)
#endif

#ifndef keen_io_sqlite3_status
#define keen_io_sqlite3_status __NS_SYMBOL(keen_io_sqlite3_status)
#endif

#ifndef keen_io_sqlite3_db_status
#define keen_io_sqlite3_db_status __NS_SYMBOL(keen_io_sqlite3_db_status)
#endif

#ifndef keen_io_sqlite3_mutex_enter
#define keen_io_sqlite3_mutex_enter __NS_SYMBOL(keen_io_sqlite3_mutex_enter)
#endif

#ifndef keen_io_sqlite3_mutex_leave
#define keen_io_sqlite3_mutex_leave __NS_SYMBOL(keen_io_sqlite3_mutex_leave)
#endif

#ifndef keen_io_sqlite3_vfs_find
#define keen_io_sqlite3_vfs_find __NS_SYMBOL(keen_io_sqlite3_vfs_find)
#endif

#ifndef keen_io_sqlite3_initialize
#define keen_io_sqlite3_initialize __NS_SYMBOL(keen_io_sqlite3_initialize)
#endif

#ifndef keen_io_sqlite3_vfs_register
#define keen_io_sqlite3_vfs_register __NS_SYMBOL(keen_io_sqlite3_vfs_register)
#endif

#ifndef keen_io_sqlite3_vfs_unregister
#define keen_io_sqlite3_vfs_unregister __NS_SYMBOL(keen_io_sqlite3_vfs_unregister)
#endif

#ifndef keen_io_sqlite3_mutex_alloc
#define keen_io_sqlite3_mutex_alloc __NS_SYMBOL(keen_io_sqlite3_mutex_alloc)
#endif

#ifndef keen_io_sqlite3_mutex_free
#define keen_io_sqlite3_mutex_free __NS_SYMBOL(keen_io_sqlite3_mutex_free)
#endif

#ifndef keen_io_sqlite3_mutex_try
#define keen_io_sqlite3_mutex_try __NS_SYMBOL(keen_io_sqlite3_mutex_try)
#endif

#ifndef keen_io_sqlite3_release_memory
#define keen_io_sqlite3_release_memory __NS_SYMBOL(keen_io_sqlite3_release_memory)
#endif

#ifndef keen_io_sqlite3_memory_alarm
#define keen_io_sqlite3_memory_alarm __NS_SYMBOL(keen_io_sqlite3_memory_alarm)
#endif

#ifndef keen_io_sqlite3_soft_heap_limit64
#define keen_io_sqlite3_soft_heap_limit64 __NS_SYMBOL(keen_io_sqlite3_soft_heap_limit64)
#endif

#ifndef keen_io_sqlite3_memory_used
#define keen_io_sqlite3_memory_used __NS_SYMBOL(keen_io_sqlite3_memory_used)
#endif

#ifndef keen_io_sqlite3_soft_heap_limit
#define keen_io_sqlite3_soft_heap_limit __NS_SYMBOL(keen_io_sqlite3_soft_heap_limit)
#endif

#ifndef keen_io_sqlite3_memory_highwater
#define keen_io_sqlite3_memory_highwater __NS_SYMBOL(keen_io_sqlite3_memory_highwater)
#endif

#ifndef keen_io_sqlite3_malloc
#define keen_io_sqlite3_malloc __NS_SYMBOL(keen_io_sqlite3_malloc)
#endif

#ifndef keen_io_sqlite3_free
#define keen_io_sqlite3_free __NS_SYMBOL(keen_io_sqlite3_free)
#endif

#ifndef keen_io_sqlite3_realloc
#define keen_io_sqlite3_realloc __NS_SYMBOL(keen_io_sqlite3_realloc)
#endif

#ifndef keen_io_sqlite3_vmprintf
#define keen_io_sqlite3_vmprintf __NS_SYMBOL(keen_io_sqlite3_vmprintf)
#endif

#ifndef keen_io_sqlite3_mprintf
#define keen_io_sqlite3_mprintf __NS_SYMBOL(keen_io_sqlite3_mprintf)
#endif

#ifndef keen_io_sqlite3_vsnprintf
#define keen_io_sqlite3_vsnprintf __NS_SYMBOL(keen_io_sqlite3_vsnprintf)
#endif

#ifndef keen_io_sqlite3_snprintf
#define keen_io_sqlite3_snprintf __NS_SYMBOL(keen_io_sqlite3_snprintf)
#endif

#ifndef keen_io_sqlite3_log
#define keen_io_sqlite3_log __NS_SYMBOL(keen_io_sqlite3_log)
#endif

#ifndef keen_io_sqlite3_randomness
#define keen_io_sqlite3_randomness __NS_SYMBOL(keen_io_sqlite3_randomness)
#endif

#ifndef keen_io_sqlite3_stricmp
#define keen_io_sqlite3_stricmp __NS_SYMBOL(keen_io_sqlite3_stricmp)
#endif

#ifndef keen_io_sqlite3_os_init
#define keen_io_sqlite3_os_init __NS_SYMBOL(keen_io_sqlite3_os_init)
#endif

#ifndef keen_io_sqlite3_os_end
#define keen_io_sqlite3_os_end __NS_SYMBOL(keen_io_sqlite3_os_end)
#endif

#ifndef keen_io_sqlite3_enable_shared_cache
#define keen_io_sqlite3_enable_shared_cache __NS_SYMBOL(keen_io_sqlite3_enable_shared_cache)
#endif

#ifndef keen_io_sqlite3_backup_init
#define keen_io_sqlite3_backup_init __NS_SYMBOL(keen_io_sqlite3_backup_init)
#endif

#ifndef keen_io_sqlite3_backup_step
#define keen_io_sqlite3_backup_step __NS_SYMBOL(keen_io_sqlite3_backup_step)
#endif

#ifndef keen_io_sqlite3_backup_finish
#define keen_io_sqlite3_backup_finish __NS_SYMBOL(keen_io_sqlite3_backup_finish)
#endif

#ifndef keen_io_sqlite3_backup_remaining
#define keen_io_sqlite3_backup_remaining __NS_SYMBOL(keen_io_sqlite3_backup_remaining)
#endif

#ifndef keen_io_sqlite3_backup_pagecount
#define keen_io_sqlite3_backup_pagecount __NS_SYMBOL(keen_io_sqlite3_backup_pagecount)
#endif

#ifndef keen_io_sqlite3_sql
#define keen_io_sqlite3_sql __NS_SYMBOL(keen_io_sqlite3_sql)
#endif

#ifndef keen_io_sqlite3_expired
#define keen_io_sqlite3_expired __NS_SYMBOL(keen_io_sqlite3_expired)
#endif

#ifndef keen_io_sqlite3_finalize
#define keen_io_sqlite3_finalize __NS_SYMBOL(keen_io_sqlite3_finalize)
#endif

#ifndef keen_io_sqlite3_reset
#define keen_io_sqlite3_reset __NS_SYMBOL(keen_io_sqlite3_reset)
#endif

#ifndef keen_io_sqlite3_clear_bindings
#define keen_io_sqlite3_clear_bindings __NS_SYMBOL(keen_io_sqlite3_clear_bindings)
#endif

#ifndef keen_io_sqlite3_value_blob
#define keen_io_sqlite3_value_blob __NS_SYMBOL(keen_io_sqlite3_value_blob)
#endif

#ifndef keen_io_sqlite3_value_text
#define keen_io_sqlite3_value_text __NS_SYMBOL(keen_io_sqlite3_value_text)
#endif

#ifndef keen_io_sqlite3_value_bytes
#define keen_io_sqlite3_value_bytes __NS_SYMBOL(keen_io_sqlite3_value_bytes)
#endif

#ifndef keen_io_sqlite3_value_bytes16
#define keen_io_sqlite3_value_bytes16 __NS_SYMBOL(keen_io_sqlite3_value_bytes16)
#endif

#ifndef keen_io_sqlite3_value_double
#define keen_io_sqlite3_value_double __NS_SYMBOL(keen_io_sqlite3_value_double)
#endif

#ifndef keen_io_sqlite3_value_int
#define keen_io_sqlite3_value_int __NS_SYMBOL(keen_io_sqlite3_value_int)
#endif

#ifndef keen_io_sqlite3_value_int64
#define keen_io_sqlite3_value_int64 __NS_SYMBOL(keen_io_sqlite3_value_int64)
#endif

#ifndef keen_io_sqlite3_value_text16
#define keen_io_sqlite3_value_text16 __NS_SYMBOL(keen_io_sqlite3_value_text16)
#endif

#ifndef keen_io_sqlite3_value_text16be
#define keen_io_sqlite3_value_text16be __NS_SYMBOL(keen_io_sqlite3_value_text16be)
#endif

#ifndef keen_io_sqlite3_value_text16le
#define keen_io_sqlite3_value_text16le __NS_SYMBOL(keen_io_sqlite3_value_text16le)
#endif

#ifndef keen_io_sqlite3_value_type
#define keen_io_sqlite3_value_type __NS_SYMBOL(keen_io_sqlite3_value_type)
#endif

#ifndef keen_io_sqlite3_result_blob
#define keen_io_sqlite3_result_blob __NS_SYMBOL(keen_io_sqlite3_result_blob)
#endif

#ifndef keen_io_sqlite3_result_double
#define keen_io_sqlite3_result_double __NS_SYMBOL(keen_io_sqlite3_result_double)
#endif

#ifndef keen_io_sqlite3_result_error
#define keen_io_sqlite3_result_error __NS_SYMBOL(keen_io_sqlite3_result_error)
#endif

#ifndef keen_io_sqlite3_result_error16
#define keen_io_sqlite3_result_error16 __NS_SYMBOL(keen_io_sqlite3_result_error16)
#endif

#ifndef keen_io_sqlite3_result_int
#define keen_io_sqlite3_result_int __NS_SYMBOL(keen_io_sqlite3_result_int)
#endif

#ifndef keen_io_sqlite3_result_int64
#define keen_io_sqlite3_result_int64 __NS_SYMBOL(keen_io_sqlite3_result_int64)
#endif

#ifndef keen_io_sqlite3_result_null
#define keen_io_sqlite3_result_null __NS_SYMBOL(keen_io_sqlite3_result_null)
#endif

#ifndef keen_io_sqlite3_result_text
#define keen_io_sqlite3_result_text __NS_SYMBOL(keen_io_sqlite3_result_text)
#endif

#ifndef keen_io_sqlite3_result_text16
#define keen_io_sqlite3_result_text16 __NS_SYMBOL(keen_io_sqlite3_result_text16)
#endif

#ifndef keen_io_sqlite3_result_text16be
#define keen_io_sqlite3_result_text16be __NS_SYMBOL(keen_io_sqlite3_result_text16be)
#endif

#ifndef keen_io_sqlite3_result_text16le
#define keen_io_sqlite3_result_text16le __NS_SYMBOL(keen_io_sqlite3_result_text16le)
#endif

#ifndef keen_io_sqlite3_result_value
#define keen_io_sqlite3_result_value __NS_SYMBOL(keen_io_sqlite3_result_value)
#endif

#ifndef keen_io_sqlite3_result_zeroblob
#define keen_io_sqlite3_result_zeroblob __NS_SYMBOL(keen_io_sqlite3_result_zeroblob)
#endif

#ifndef keen_io_sqlite3_result_error_code
#define keen_io_sqlite3_result_error_code __NS_SYMBOL(keen_io_sqlite3_result_error_code)
#endif

#ifndef keen_io_sqlite3_result_error_toobig
#define keen_io_sqlite3_result_error_toobig __NS_SYMBOL(keen_io_sqlite3_result_error_toobig)
#endif

#ifndef keen_io_sqlite3_result_error_nomem
#define keen_io_sqlite3_result_error_nomem __NS_SYMBOL(keen_io_sqlite3_result_error_nomem)
#endif

#ifndef keen_io_sqlite3_step
#define keen_io_sqlite3_step __NS_SYMBOL(keen_io_sqlite3_step)
#endif

#ifndef keen_io_sqlite3_user_data
#define keen_io_sqlite3_user_data __NS_SYMBOL(keen_io_sqlite3_user_data)
#endif

#ifndef keen_io_sqlite3_context_db_handle
#define keen_io_sqlite3_context_db_handle __NS_SYMBOL(keen_io_sqlite3_context_db_handle)
#endif

#ifndef keen_io_sqlite3_aggregate_context
#define keen_io_sqlite3_aggregate_context __NS_SYMBOL(keen_io_sqlite3_aggregate_context)
#endif

#ifndef keen_io_sqlite3_get_auxdata
#define keen_io_sqlite3_get_auxdata __NS_SYMBOL(keen_io_sqlite3_get_auxdata)
#endif

#ifndef keen_io_sqlite3_set_auxdata
#define keen_io_sqlite3_set_auxdata __NS_SYMBOL(keen_io_sqlite3_set_auxdata)
#endif

#ifndef keen_io_sqlite3_aggregate_count
#define keen_io_sqlite3_aggregate_count __NS_SYMBOL(keen_io_sqlite3_aggregate_count)
#endif

#ifndef keen_io_sqlite3_column_count
#define keen_io_sqlite3_column_count __NS_SYMBOL(keen_io_sqlite3_column_count)
#endif

#ifndef keen_io_sqlite3_data_count
#define keen_io_sqlite3_data_count __NS_SYMBOL(keen_io_sqlite3_data_count)
#endif

#ifndef keen_io_sqlite3_column_blob
#define keen_io_sqlite3_column_blob __NS_SYMBOL(keen_io_sqlite3_column_blob)
#endif

#ifndef keen_io_sqlite3_column_bytes
#define keen_io_sqlite3_column_bytes __NS_SYMBOL(keen_io_sqlite3_column_bytes)
#endif

#ifndef keen_io_sqlite3_column_bytes16
#define keen_io_sqlite3_column_bytes16 __NS_SYMBOL(keen_io_sqlite3_column_bytes16)
#endif

#ifndef keen_io_sqlite3_column_double
#define keen_io_sqlite3_column_double __NS_SYMBOL(keen_io_sqlite3_column_double)
#endif

#ifndef keen_io_sqlite3_column_int
#define keen_io_sqlite3_column_int __NS_SYMBOL(keen_io_sqlite3_column_int)
#endif

#ifndef keen_io_sqlite3_column_int64
#define keen_io_sqlite3_column_int64 __NS_SYMBOL(keen_io_sqlite3_column_int64)
#endif

#ifndef keen_io_sqlite3_column_text
#define keen_io_sqlite3_column_text __NS_SYMBOL(keen_io_sqlite3_column_text)
#endif

#ifndef keen_io_sqlite3_column_value
#define keen_io_sqlite3_column_value __NS_SYMBOL(keen_io_sqlite3_column_value)
#endif

#ifndef keen_io_sqlite3_column_text16
#define keen_io_sqlite3_column_text16 __NS_SYMBOL(keen_io_sqlite3_column_text16)
#endif

#ifndef keen_io_sqlite3_column_type
#define keen_io_sqlite3_column_type __NS_SYMBOL(keen_io_sqlite3_column_type)
#endif

#ifndef keen_io_sqlite3_column_name
#define keen_io_sqlite3_column_name __NS_SYMBOL(keen_io_sqlite3_column_name)
#endif

#ifndef keen_io_sqlite3_column_name16
#define keen_io_sqlite3_column_name16 __NS_SYMBOL(keen_io_sqlite3_column_name16)
#endif

#ifndef keen_io_sqlite3_column_decltype
#define keen_io_sqlite3_column_decltype __NS_SYMBOL(keen_io_sqlite3_column_decltype)
#endif

#ifndef keen_io_sqlite3_column_decltype16
#define keen_io_sqlite3_column_decltype16 __NS_SYMBOL(keen_io_sqlite3_column_decltype16)
#endif

#ifndef keen_io_sqlite3_bind_blob
#define keen_io_sqlite3_bind_blob __NS_SYMBOL(keen_io_sqlite3_bind_blob)
#endif

#ifndef keen_io_sqlite3_bind_double
#define keen_io_sqlite3_bind_double __NS_SYMBOL(keen_io_sqlite3_bind_double)
#endif

#ifndef keen_io_sqlite3_bind_int
#define keen_io_sqlite3_bind_int __NS_SYMBOL(keen_io_sqlite3_bind_int)
#endif

#ifndef keen_io_sqlite3_bind_int64
#define keen_io_sqlite3_bind_int64 __NS_SYMBOL(keen_io_sqlite3_bind_int64)
#endif

#ifndef keen_io_sqlite3_bind_null
#define keen_io_sqlite3_bind_null __NS_SYMBOL(keen_io_sqlite3_bind_null)
#endif

#ifndef keen_io_sqlite3_bind_text
#define keen_io_sqlite3_bind_text __NS_SYMBOL(keen_io_sqlite3_bind_text)
#endif

#ifndef keen_io_sqlite3_bind_text16
#define keen_io_sqlite3_bind_text16 __NS_SYMBOL(keen_io_sqlite3_bind_text16)
#endif

#ifndef keen_io_sqlite3_bind_value
#define keen_io_sqlite3_bind_value __NS_SYMBOL(keen_io_sqlite3_bind_value)
#endif

#ifndef keen_io_sqlite3_bind_zeroblob
#define keen_io_sqlite3_bind_zeroblob __NS_SYMBOL(keen_io_sqlite3_bind_zeroblob)
#endif

#ifndef keen_io_sqlite3_bind_parameter_count
#define keen_io_sqlite3_bind_parameter_count __NS_SYMBOL(keen_io_sqlite3_bind_parameter_count)
#endif

#ifndef keen_io_sqlite3_bind_parameter_name
#define keen_io_sqlite3_bind_parameter_name __NS_SYMBOL(keen_io_sqlite3_bind_parameter_name)
#endif

#ifndef keen_io_sqlite3_bind_parameter_index
#define keen_io_sqlite3_bind_parameter_index __NS_SYMBOL(keen_io_sqlite3_bind_parameter_index)
#endif

#ifndef keen_io_sqlite3_transfer_bindings
#define keen_io_sqlite3_transfer_bindings __NS_SYMBOL(keen_io_sqlite3_transfer_bindings)
#endif

#ifndef keen_io_sqlite3_db_handle
#define keen_io_sqlite3_db_handle __NS_SYMBOL(keen_io_sqlite3_db_handle)
#endif

#ifndef keen_io_sqlite3_stmt_readonly
#define keen_io_sqlite3_stmt_readonly __NS_SYMBOL(keen_io_sqlite3_stmt_readonly)
#endif

#ifndef keen_io_sqlite3_stmt_busy
#define keen_io_sqlite3_stmt_busy __NS_SYMBOL(keen_io_sqlite3_stmt_busy)
#endif

#ifndef keen_io_sqlite3_next_stmt
#define keen_io_sqlite3_next_stmt __NS_SYMBOL(keen_io_sqlite3_next_stmt)
#endif

#ifndef keen_io_sqlite3_stmt_status
#define keen_io_sqlite3_stmt_status __NS_SYMBOL(keen_io_sqlite3_stmt_status)
#endif

#ifndef keen_io_sqlite3_value_numeric_type
#define keen_io_sqlite3_value_numeric_type __NS_SYMBOL(keen_io_sqlite3_value_numeric_type)
#endif

#ifndef keen_io_sqlite3_blob_open
#define keen_io_sqlite3_blob_open __NS_SYMBOL(keen_io_sqlite3_blob_open)
#endif

#ifndef keen_io_sqlite3_blob_close
#define keen_io_sqlite3_blob_close __NS_SYMBOL(keen_io_sqlite3_blob_close)
#endif

#ifndef keen_io_sqlite3_blob_read
#define keen_io_sqlite3_blob_read __NS_SYMBOL(keen_io_sqlite3_blob_read)
#endif

#ifndef keen_io_sqlite3_blob_write
#define keen_io_sqlite3_blob_write __NS_SYMBOL(keen_io_sqlite3_blob_write)
#endif

#ifndef keen_io_sqlite3_blob_bytes
#define keen_io_sqlite3_blob_bytes __NS_SYMBOL(keen_io_sqlite3_blob_bytes)
#endif

#ifndef keen_io_sqlite3_blob_reopen
#define keen_io_sqlite3_blob_reopen __NS_SYMBOL(keen_io_sqlite3_blob_reopen)
#endif

#ifndef keen_io_sqlite3_set_authorizer
#define keen_io_sqlite3_set_authorizer __NS_SYMBOL(keen_io_sqlite3_set_authorizer)
#endif

#ifndef keen_io_sqlite3_strglob
#define keen_io_sqlite3_strglob __NS_SYMBOL(keen_io_sqlite3_strglob)
#endif

#ifndef keen_io_sqlite3_exec
#define keen_io_sqlite3_exec __NS_SYMBOL(keen_io_sqlite3_exec)
#endif

#ifndef keen_io_sqlite3_prepare_v2
#define keen_io_sqlite3_prepare_v2 __NS_SYMBOL(keen_io_sqlite3_prepare_v2)
#endif

#ifndef keen_io_sqlite3_errcode
#define keen_io_sqlite3_errcode __NS_SYMBOL(keen_io_sqlite3_errcode)
#endif

#ifndef keen_io_sqlite3_errmsg
#define keen_io_sqlite3_errmsg __NS_SYMBOL(keen_io_sqlite3_errmsg)
#endif

#ifndef keen_io_sqlite3_load_extension
#define keen_io_sqlite3_load_extension __NS_SYMBOL(keen_io_sqlite3_load_extension)
#endif

#ifndef keen_io_sqlite3_enable_load_extension
#define keen_io_sqlite3_enable_load_extension __NS_SYMBOL(keen_io_sqlite3_enable_load_extension)
#endif

#ifndef keen_io_sqlite3_auto_extension
#define keen_io_sqlite3_auto_extension __NS_SYMBOL(keen_io_sqlite3_auto_extension)
#endif

#ifndef keen_io_sqlite3_cancel_auto_extension
#define keen_io_sqlite3_cancel_auto_extension __NS_SYMBOL(keen_io_sqlite3_cancel_auto_extension)
#endif

#ifndef keen_io_sqlite3_reset_auto_extension
#define keen_io_sqlite3_reset_auto_extension __NS_SYMBOL(keen_io_sqlite3_reset_auto_extension)
#endif

#ifndef keen_io_sqlite3_prepare
#define keen_io_sqlite3_prepare __NS_SYMBOL(keen_io_sqlite3_prepare)
#endif

#ifndef keen_io_sqlite3_prepare16
#define keen_io_sqlite3_prepare16 __NS_SYMBOL(keen_io_sqlite3_prepare16)
#endif

#ifndef keen_io_sqlite3_prepare16_v2
#define keen_io_sqlite3_prepare16_v2 __NS_SYMBOL(keen_io_sqlite3_prepare16_v2)
#endif

#ifndef keen_io_sqlite3_get_table
#define keen_io_sqlite3_get_table __NS_SYMBOL(keen_io_sqlite3_get_table)
#endif

#ifndef keen_io_sqlite3_free_table
#define keen_io_sqlite3_free_table __NS_SYMBOL(keen_io_sqlite3_free_table)
#endif

#ifndef keen_io_sqlite3_create_module
#define keen_io_sqlite3_create_module __NS_SYMBOL(keen_io_sqlite3_create_module)
#endif

#ifndef keen_io_sqlite3_create_module_v2
#define keen_io_sqlite3_create_module_v2 __NS_SYMBOL(keen_io_sqlite3_create_module_v2)
#endif

#ifndef keen_io_sqlite3_declare_vtab
#define keen_io_sqlite3_declare_vtab __NS_SYMBOL(keen_io_sqlite3_declare_vtab)
#endif

#ifndef keen_io_sqlite3_vtab_on_conflict
#define keen_io_sqlite3_vtab_on_conflict __NS_SYMBOL(keen_io_sqlite3_vtab_on_conflict)
#endif

#ifndef keen_io_sqlite3_vtab_config
#define keen_io_sqlite3_vtab_config __NS_SYMBOL(keen_io_sqlite3_vtab_config)
#endif

#ifndef keen_io_sqlite3_complete
#define keen_io_sqlite3_complete __NS_SYMBOL(keen_io_sqlite3_complete)
#endif

#ifndef keen_io_sqlite3_complete16
#define keen_io_sqlite3_complete16 __NS_SYMBOL(keen_io_sqlite3_complete16)
#endif

#ifndef keen_io_sqlite3_libversion
#define keen_io_sqlite3_libversion __NS_SYMBOL(keen_io_sqlite3_libversion)
#endif

#ifndef keen_io_sqlite3_sourceid
#define keen_io_sqlite3_sourceid __NS_SYMBOL(keen_io_sqlite3_sourceid)
#endif

#ifndef keen_io_sqlite3_libversion_number
#define keen_io_sqlite3_libversion_number __NS_SYMBOL(keen_io_sqlite3_libversion_number)
#endif

#ifndef keen_io_sqlite3_threadsafe
#define keen_io_sqlite3_threadsafe __NS_SYMBOL(keen_io_sqlite3_threadsafe)
#endif

#ifndef keen_io_sqlite3_shutdown
#define keen_io_sqlite3_shutdown __NS_SYMBOL(keen_io_sqlite3_shutdown)
#endif

#ifndef keen_io_sqlite3_config
#define keen_io_sqlite3_config __NS_SYMBOL(keen_io_sqlite3_config)
#endif

#ifndef keen_io_sqlite3_db_mutex
#define keen_io_sqlite3_db_mutex __NS_SYMBOL(keen_io_sqlite3_db_mutex)
#endif

#ifndef keen_io_sqlite3_db_release_memory
#define keen_io_sqlite3_db_release_memory __NS_SYMBOL(keen_io_sqlite3_db_release_memory)
#endif

#ifndef keen_io_sqlite3_db_config
#define keen_io_sqlite3_db_config __NS_SYMBOL(keen_io_sqlite3_db_config)
#endif

#ifndef keen_io_sqlite3_last_insert_rowid
#define keen_io_sqlite3_last_insert_rowid __NS_SYMBOL(keen_io_sqlite3_last_insert_rowid)
#endif

#ifndef keen_io_sqlite3_changes
#define keen_io_sqlite3_changes __NS_SYMBOL(keen_io_sqlite3_changes)
#endif

#ifndef keen_io_sqlite3_total_changes
#define keen_io_sqlite3_total_changes __NS_SYMBOL(keen_io_sqlite3_total_changes)
#endif

#ifndef keen_io_sqlite3_close
#define keen_io_sqlite3_close __NS_SYMBOL(keen_io_sqlite3_close)
#endif

#ifndef keen_io_sqlite3_close_v2
#define keen_io_sqlite3_close_v2 __NS_SYMBOL(keen_io_sqlite3_close_v2)
#endif

#ifndef keen_io_sqlite3_busy_handler
#define keen_io_sqlite3_busy_handler __NS_SYMBOL(keen_io_sqlite3_busy_handler)
#endif

#ifndef keen_io_sqlite3_progress_handler
#define keen_io_sqlite3_progress_handler __NS_SYMBOL(keen_io_sqlite3_progress_handler)
#endif

#ifndef keen_io_sqlite3_busy_timeout
#define keen_io_sqlite3_busy_timeout __NS_SYMBOL(keen_io_sqlite3_busy_timeout)
#endif

#ifndef keen_io_sqlite3_interrupt
#define keen_io_sqlite3_interrupt __NS_SYMBOL(keen_io_sqlite3_interrupt)
#endif

#ifndef keen_io_sqlite3_create_function
#define keen_io_sqlite3_create_function __NS_SYMBOL(keen_io_sqlite3_create_function)
#endif

#ifndef keen_io_sqlite3_create_function_v2
#define keen_io_sqlite3_create_function_v2 __NS_SYMBOL(keen_io_sqlite3_create_function_v2)
#endif

#ifndef keen_io_sqlite3_create_function16
#define keen_io_sqlite3_create_function16 __NS_SYMBOL(keen_io_sqlite3_create_function16)
#endif

#ifndef keen_io_sqlite3_overload_function
#define keen_io_sqlite3_overload_function __NS_SYMBOL(keen_io_sqlite3_overload_function)
#endif

#ifndef keen_io_sqlite3_trace
#define keen_io_sqlite3_trace __NS_SYMBOL(keen_io_sqlite3_trace)
#endif

#ifndef keen_io_sqlite3_profile
#define keen_io_sqlite3_profile __NS_SYMBOL(keen_io_sqlite3_profile)
#endif

#ifndef keen_io_sqlite3_commit_hook
#define keen_io_sqlite3_commit_hook __NS_SYMBOL(keen_io_sqlite3_commit_hook)
#endif

#ifndef keen_io_sqlite3_update_hook
#define keen_io_sqlite3_update_hook __NS_SYMBOL(keen_io_sqlite3_update_hook)
#endif

#ifndef keen_io_sqlite3_rollback_hook
#define keen_io_sqlite3_rollback_hook __NS_SYMBOL(keen_io_sqlite3_rollback_hook)
#endif

#ifndef keen_io_sqlite3_wal_autocheckpoint
#define keen_io_sqlite3_wal_autocheckpoint __NS_SYMBOL(keen_io_sqlite3_wal_autocheckpoint)
#endif

#ifndef keen_io_sqlite3_wal_hook
#define keen_io_sqlite3_wal_hook __NS_SYMBOL(keen_io_sqlite3_wal_hook)
#endif

#ifndef keen_io_sqlite3_wal_checkpoint_v2
#define keen_io_sqlite3_wal_checkpoint_v2 __NS_SYMBOL(keen_io_sqlite3_wal_checkpoint_v2)
#endif

#ifndef keen_io_sqlite3_wal_checkpoint
#define keen_io_sqlite3_wal_checkpoint __NS_SYMBOL(keen_io_sqlite3_wal_checkpoint)
#endif

#ifndef keen_io_sqlite3_errmsg16
#define keen_io_sqlite3_errmsg16 __NS_SYMBOL(keen_io_sqlite3_errmsg16)
#endif

#ifndef keen_io_sqlite3_extended_errcode
#define keen_io_sqlite3_extended_errcode __NS_SYMBOL(keen_io_sqlite3_extended_errcode)
#endif

#ifndef keen_io_sqlite3_errstr
#define keen_io_sqlite3_errstr __NS_SYMBOL(keen_io_sqlite3_errstr)
#endif

#ifndef keen_io_sqlite3_limit
#define keen_io_sqlite3_limit __NS_SYMBOL(keen_io_sqlite3_limit)
#endif

#ifndef keen_io_sqlite3_open
#define keen_io_sqlite3_open __NS_SYMBOL(keen_io_sqlite3_open)
#endif

#ifndef keen_io_sqlite3_open_v2
#define keen_io_sqlite3_open_v2 __NS_SYMBOL(keen_io_sqlite3_open_v2)
#endif

#ifndef keen_io_sqlite3_open16
#define keen_io_sqlite3_open16 __NS_SYMBOL(keen_io_sqlite3_open16)
#endif

#ifndef keen_io_sqlite3_create_collation
#define keen_io_sqlite3_create_collation __NS_SYMBOL(keen_io_sqlite3_create_collation)
#endif

#ifndef keen_io_sqlite3_create_collation_v2
#define keen_io_sqlite3_create_collation_v2 __NS_SYMBOL(keen_io_sqlite3_create_collation_v2)
#endif

#ifndef keen_io_sqlite3_create_collation16
#define keen_io_sqlite3_create_collation16 __NS_SYMBOL(keen_io_sqlite3_create_collation16)
#endif

#ifndef keen_io_sqlite3_collation_needed
#define keen_io_sqlite3_collation_needed __NS_SYMBOL(keen_io_sqlite3_collation_needed)
#endif

#ifndef keen_io_sqlite3_collation_needed16
#define keen_io_sqlite3_collation_needed16 __NS_SYMBOL(keen_io_sqlite3_collation_needed16)
#endif

#ifndef keen_io_sqlite3_global_recover
#define keen_io_sqlite3_global_recover __NS_SYMBOL(keen_io_sqlite3_global_recover)
#endif

#ifndef keen_io_sqlite3_get_autocommit
#define keen_io_sqlite3_get_autocommit __NS_SYMBOL(keen_io_sqlite3_get_autocommit)
#endif

#ifndef keen_io_sqlite3_thread_cleanup
#define keen_io_sqlite3_thread_cleanup __NS_SYMBOL(keen_io_sqlite3_thread_cleanup)
#endif

#ifndef keen_io_sqlite3_sleep
#define keen_io_sqlite3_sleep __NS_SYMBOL(keen_io_sqlite3_sleep)
#endif

#ifndef keen_io_sqlite3_extended_result_codes
#define keen_io_sqlite3_extended_result_codes __NS_SYMBOL(keen_io_sqlite3_extended_result_codes)
#endif

#ifndef keen_io_sqlite3_file_control
#define keen_io_sqlite3_file_control __NS_SYMBOL(keen_io_sqlite3_file_control)
#endif

#ifndef keen_io_sqlite3_test_control
#define keen_io_sqlite3_test_control __NS_SYMBOL(keen_io_sqlite3_test_control)
#endif

#ifndef keen_io_sqlite3_uri_parameter
#define keen_io_sqlite3_uri_parameter __NS_SYMBOL(keen_io_sqlite3_uri_parameter)
#endif

#ifndef keen_io_sqlite3_uri_boolean
#define keen_io_sqlite3_uri_boolean __NS_SYMBOL(keen_io_sqlite3_uri_boolean)
#endif

#ifndef keen_io_sqlite3_uri_int64
#define keen_io_sqlite3_uri_int64 __NS_SYMBOL(keen_io_sqlite3_uri_int64)
#endif

#ifndef keen_io_sqlite3_db_filename
#define keen_io_sqlite3_db_filename __NS_SYMBOL(keen_io_sqlite3_db_filename)
#endif

#ifndef keen_io_sqlite3_db_readonly
#define keen_io_sqlite3_db_readonly __NS_SYMBOL(keen_io_sqlite3_db_readonly)
#endif

// Externs
#ifndef KIOkReachabilityChangedNotification
#define KIOkReachabilityChangedNotification __NS_SYMBOL(KIOkReachabilityChangedNotification)
#endif

#ifndef kKeenApiUrlScheme
#define kKeenApiUrlScheme __NS_SYMBOL(kKeenApiUrlScheme)
#endif

#ifndef kKeenDefaultApiUrlAuthority
#define kKeenDefaultApiUrlAuthority __NS_SYMBOL(kKeenDefaultApiUrlAuthority)
#endif

#ifndef kKeenApiVersion
#define kKeenApiVersion __NS_SYMBOL(kKeenApiVersion)
#endif

#ifndef kKeenNameParam
#define kKeenNameParam __NS_SYMBOL(kKeenNameParam)
#endif

#ifndef kKeenDescriptionParam
#define kKeenDescriptionParam __NS_SYMBOL(kKeenDescriptionParam)
#endif

#ifndef kKeenSuccessParam
#define kKeenSuccessParam __NS_SYMBOL(kKeenSuccessParam)
#endif

#ifndef kKeenErrorParam
#define kKeenErrorParam __NS_SYMBOL(kKeenErrorParam)
#endif

#ifndef kKeenErrorCodeParam
#define kKeenErrorCodeParam __NS_SYMBOL(kKeenErrorCodeParam)
#endif

#ifndef kKeenInvalidCollectionNameError
#define kKeenInvalidCollectionNameError __NS_SYMBOL(kKeenInvalidCollectionNameError)
#endif

#ifndef kKeenInvalidPropertyNameError
#define kKeenInvalidPropertyNameError __NS_SYMBOL(kKeenInvalidPropertyNameError)
#endif

#ifndef kKeenInvalidPropertyValueError
#define kKeenInvalidPropertyValueError __NS_SYMBOL(kKeenInvalidPropertyValueError)
#endif

#ifndef kKeenErrorDomain
#define kKeenErrorDomain __NS_SYMBOL(kKeenErrorDomain)
#endif

#ifndef kKeenSdkVersionHeader
#define kKeenSdkVersionHeader __NS_SYMBOL(kKeenSdkVersionHeader)
#endif

#ifndef kKeenSdkVersionWithPlatform
#define kKeenSdkVersionWithPlatform __NS_SYMBOL(kKeenSdkVersionWithPlatform)
#endif

#ifndef kKeenFileStoreImportedKey
#define kKeenFileStoreImportedKey __NS_SYMBOL(kKeenFileStoreImportedKey)
#endif

#ifndef kKeenMaxEventsPerCollection
#define kKeenMaxEventsPerCollection __NS_SYMBOL(kKeenMaxEventsPerCollection)
#endif

#ifndef kKeenNumberEventsToForget
#define kKeenNumberEventsToForget __NS_SYMBOL(kKeenNumberEventsToForget)
#endif

#ifndef keen_io_sqlite3_version
#define keen_io_sqlite3_version __NS_SYMBOL(keen_io_sqlite3_version)
#endif

#ifndef keen_io_sqlite3_temp_directory
#define keen_io_sqlite3_temp_directory __NS_SYMBOL(keen_io_sqlite3_temp_directory)
#endif

#ifndef keen_io_sqlite3_data_directory
#define keen_io_sqlite3_data_directory __NS_SYMBOL(keen_io_sqlite3_data_directory)
#endif

