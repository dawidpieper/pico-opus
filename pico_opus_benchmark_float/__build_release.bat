if exist build rmdir /s /q build
md build
cd build
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release --fresh
ninja piwu_benchmark_float
cd ..