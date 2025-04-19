// sync_test.c
uint64_t start = mach_absolute_time();
dsp_send_command(BENCHMARK_CMD);
while(!dsp_ready());
uint64_t delta = mach_absolute_time() - start;
printf("Latency: %.2fμs\n", (double)delta/1000.0);