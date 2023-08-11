if exist build rmdir /s /q build
md build
cd build
cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Debug --fresh
ninja piwu
cd ..