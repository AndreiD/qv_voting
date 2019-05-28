:: -> Go Bindings
cd ..
rmdir /Q /S bindings
ROBOCOPY contracts\ bindings\ /E
cd bindings
del "Migrations.sol"
solcjs.cmd --abi --bin JobGenerator.sol &&  abigen.exe --bin=JobGenerator_sol_JobGenerator.bin --abi=JobGenerator_sol_JobGenerator.abi --pkg=smartcontracts --out=JobGenerator.go && del "*.bin" && del "*.abi"
