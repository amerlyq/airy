#include <dlt.h>
#include <cstdlib>

int main(int argc, char** argv) {
    DLT_REGISTER_APP("TST", "test");
    DLT_DECLARE_CONTEXT(g_DltCtx);
    DLT_REGISTER_CONTEXT(g_DltCtx, "TST", "test");
    DLT_REGISTER_LOG_LEVEL_CHANGED_CALLBACK(g_DltCtx,
    [](char* context_id, uint8_t log_level, uint8_t trace_status){
        printf("%s : %d : %d\n", context_id, log_level, trace_status);
    });
    sleep(2);
    DLT_LOG(g_DltCtx, DLT_LOG_FATAL, DLT_CSTRING("fatal"));
    DLT_LOG(g_DltCtx, DLT_LOG_ERROR, DLT_CSTRING("error"));
    DLT_LOG(g_DltCtx, DLT_LOG_WARN, DLT_CSTRING("warn"));
    DLT_LOG(g_DltCtx, DLT_LOG_INFO, DLT_CSTRING("info"));
    // abort();  // TEST: if last log msgs aren't eaten
    DLT_LOG(g_DltCtx, DLT_LOG_DEBUG, DLT_CSTRING("debug"));
    DLT_LOG(g_DltCtx, DLT_LOG_VERBOSE, DLT_CSTRING("verbose"));
    DLT_UNREGISTER_CONTEXT(g_DltCtx);
    DLT_UNREGISTER_APP();
    return 0;
}
