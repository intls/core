ADMIN_TO_VERIFY=$1
LENSHUB="0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5"
STORAGE_SLOT=29

SLOT=$(cast abi-encode "a(address,uint256)" $ADMIN_TO_VERIFY $STORAGE_SLOT)

KECCAK_HASH=$(cast keccak $SLOT)

cast storage --rpc-url mumbai $LENSHUB $KECCAK_HASH