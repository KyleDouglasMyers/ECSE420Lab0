
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "lodepng.h"
#include <stdio.h>



__global__ void rectifyKernel(unsigned char* managed_image, int batch)
{
	//int threadId = threadIdx.x + blockIdx.x * blockDim.x;

	printf("Thread %d\n", threadIdx.x);

	int x = threadIdx.x * batch;

	for (int i = x; i < x + batch; i++) {
		if (managed_image[i] < 127) {
			managed_image[i] = 127;
		}
	}
}


void rectify(char* input_filename, char* output_filename, int threads)
{
	unsigned error;
	unsigned char* image, * new_image, * managed_image, * managed_new_image;
	unsigned width, height;

	error = lodepng_decode32_file(&image, &width, &height, input_filename);
	if (error) printf("error %u: %s\n", error, lodepng_error_text(error));

	//malloc some space in gpu memory

	int batch = width * height * 4 / threads;

	cudaMalloc((void**)&managed_image, width * height * 4 * sizeof(unsigned char));
	
	cudaMalloc((void**)&managed_new_image, width * height * 4 * sizeof(unsigned char)); 
	
	cudaMemcpy(managed_image, image, width * height * 4 * sizeof(unsigned char), cudaMemcpyHostToDevice);



	//CUDA call
	rectifyKernel <<< 1, threads >>> (managed_image, batch);

	cudaMemcpy(image, managed_image, width * height * 4 * sizeof(unsigned char), cudaMemcpyDeviceToHost);

	lodepng_encode32_file(output_filename, image, width, height);

	free(image);
	//free(new_image);
}


int main()
{
	char input_filename[] = "Test_1.png";
	char rectify_output_filename[] = "myRectifiedPic.png";
	char pool_output_filename[] = "myPooledPic.png";


	rectify(input_filename, rectify_output_filename, 4);

	return 0;
}