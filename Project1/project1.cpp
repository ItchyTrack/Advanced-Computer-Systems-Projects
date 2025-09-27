#include <chrono>
#include <iostream>
#include <cstdlib>

#if SAXPY
	#define IN_ARRAY_COUT 2
	#define OUT_ARRAY_COUT true
#elif DOT_PRODUCT
	#define IN_ARRAY_COUT 2
	#define OUT_ARRAY_COUT false
#elif ELEMENTWISE_MULTIPLY
	#define IN_ARRAY_COUT 2
	#define OUT_ARRAY_COUT true
#elif STENCIL
	#define IN_ARRAY_COUT 3
	#define OUT_ARRAY_COUT true
#endif

#ifndef STRIDE
#define STRIDE 1
#endif

template<class number_t>
number_t randomNum() {
    return static_cast<number_t>(rand()) / RAND_MAX;
}
template<class number_t>
number_t* alloct(const unsigned int size) {
#ifdef DO_MISSALIGNMENT
	return (number_t*)std::aligned_alloc(16, (size*sizeof(number_t)+8 + 15) & ~15) + 8/sizeof(number_t);
#else
	return (number_t*)std::aligned_alloc(16, (size*sizeof(number_t) + 15) & ~15);
#endif
}
template<class number_t>
void  dealloct(number_t* ptr) {
#ifdef DO_MISSALIGNMENT
	std::free(ptr-8/sizeof(number_t));
#else
	std::free(ptr);
#endif
}

template<class number_t>
void test(const unsigned int size) {
#if IN_ARRAY_COUT >= 1
	number_t* inArray1 = alloct<number_t>(size);
	for (unsigned int i = 0; i < size; i++) {
		inArray1[i] = randomNum<number_t>();
	}
#endif
#if IN_ARRAY_COUT >= 2
	number_t* inArray2 = alloct<number_t>(size);
	for (unsigned int i = 0; i < size; i++) {
		inArray2[i] = randomNum<number_t>();
	}
#endif
#if IN_ARRAY_COUT >= 3
	number_t* inArray3 = alloct<number_t>(size);
	for (unsigned int i = 0; i < size; i++) {
		inArray3[i] = randomNum<number_t>();
	}
#endif
#if OUT_ARRAY_COUT == true
    number_t* outArray = alloct<number_t>(size);
#else
	number_t outValue = 0;
#endif

	auto start = std::chrono::high_resolution_clock::now();

	for (unsigned long long s = 0; s < STRIDE; s++) {
		for (unsigned long long i = s; i < size; i += STRIDE) {
#if SAXPY
			outArray[i] = inArray1[i] * number_t(0.8123) + inArray2[i];
#elif DOT_PRODUCT
			outValue += inArray1[i] * inArray2[i];
#elif ELEMENTWISE_MULTIPLY
			outArray[i] = inArray1[i] * inArray2[i];
#elif STENCIL
			outArray[i] = inArray1[i] * number_t(0.1040924) + inArray2[i] * number_t(0.56452) + inArray1[i] * number_t(0.98124);
#endif
		}
	}

    auto duration = std::chrono::high_resolution_clock::now() - start;
    std::cout << std::chrono::duration_cast<std::chrono::nanoseconds>(duration).count() / 1e9;
#if OUT_ARRAY_COUT == true
	asm volatile("" : : "m"(outArray) : "memory"); // forces it to exist
	dealloct<number_t>(outArray);
#else
	asm volatile("" : : "m"(outValue) : "memory"); // forces it to exist
#endif
#if IN_ARRAY_COUT >= 1
	dealloct<number_t>(inArray1);
#endif
#if IN_ARRAY_COUT >= 2
	dealloct<number_t>(inArray2);
#endif
#if IN_ARRAY_COUT >= 3
	dealloct<number_t>(inArray3);
#endif
}

int main(int argc, char** argv) {
	unsigned int size = std::stoi(argv[1]);
#ifdef DO_ODD_SIZE
	size += 1;
#endif
#ifdef USE_DOUBLE
	test<double>(size);
#else
	test<float>(size);
#endif
}
