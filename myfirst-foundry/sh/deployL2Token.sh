# 部署 L1 对应的 L2 对应 代币

#./deployL2Token.sh $SEPOLIA_BASE_RPC_URL $VALUE_PRIVATE_KEY
# 调用合约: OptimismMintableERC20Factory
# 在L2网络上创建对应的l2_token
# rpc-url(op sepolia RPC节点的地址): https://optimism-sepolia.api.onfinality.io/public
cast send 0x4200000000000000000000000000000000000012 \
  "createOptimismMintableERC20(address,string,string)" \
  "0x63eDa7FbC6046E46254220f19525A4332B6415D1" \
  "L1 Token" \
  "L1T" \
  --rpc-url $1 \
  --private-key $2


# example: 0x5F15A30Ba90C7598FaDc9BBfa52859948f2CD2bA