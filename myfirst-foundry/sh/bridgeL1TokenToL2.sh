# 部署 L1 对应的 L2 对应 代币

#./bridgeL1TokenToL2.sh $SEPOLIA_RPC_URL $VALUE_PRIVATE_KEY


# approve first 
# 批准 L1 桥合约转移你的代币
# rpc-url(sepolia RPC节点的地址): https://ethereum-sepolia.rpc.subquery.network/public
cast send 0x63eDa7FbC6046E46254220f19525A4332B6415D1 \
  "approve(address,uint256)" \
  "0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1" \
  "10000000000000000000000" \
  --rpc-url $1 \
  --private-key $2

# 调用合约: L1StandardBridgeProxy
# 调⽤L1StandardBridge的bridgeERC20() , 锁定或burn L1 token，并触发相应的事件
# rpc-url(sepolia RPC节点的地址): https://ethereum-sepolia.rpc.subquery.network/public
cast send 0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1 \
  "bridgeERC20(address,address,uint256,uint32,bytes)" \
  "0x63eDa7FbC6046E46254220f19525A4332B6415D1" \
  "0x5F15A30Ba90C7598FaDc9BBfa52859948f2CD2bA" \
  "10000000000" \
  "1000000" \
  "0x" \
  --rpc-url $1 \
  --private-key $2

