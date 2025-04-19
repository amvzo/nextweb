// Hypothetical FPU-accelerated DCT block processing
FPU_enable();
FPU_load_matrix(jpeg_block);
FPU_fdct(); // Hardware-accelerated DCT
FPU_store_matrix(output_buffer);
FPU_disable();