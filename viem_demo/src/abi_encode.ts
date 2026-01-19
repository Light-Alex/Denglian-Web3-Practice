import { encodeAbiParameters, parseEther } from "viem";

const main = async () => {
    // 编码uint256
    var data = parseEther("0.000001");
    const encodedUint256 = encodeAbiParameters(
        [{ type: "uint256" }],
        [data]
    );
    console.log(`The parsed ether is ${data}`);
    console.log(`The encoded data is ${encodedUint256}`);
}

main();