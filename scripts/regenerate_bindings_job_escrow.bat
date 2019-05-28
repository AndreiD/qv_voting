:: -> Go Bindings
cd ..
rmdir /Q /S bindings
ROBOCOPY contracts\ bindings\ /E
cd bindings
del "Migrations.sol"
solcjs.cmd --abi --bin JobEscrow.sol &&  abigen.exe --bin=JobEscrow_sol_JobEscrow.bin --abi=JobEscrow_sol_JobEscrow.abi --pkg=smartcontracts --out=JobEscrow.go && del "*.bin" && del "*.abi"
