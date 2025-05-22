import { ethers, JsonRpcSigner } from "ethers";

import helperApproveAndSwap from "./HelperApproveAndSwap.json";
import { populateAndSignAuthAddress } from "./authorization-signer";
import { createCustomCommon, Hardfork, Mainnet } from "@ethereumjs/common";
import { createEOACode7702Tx } from "@ethereumjs/tx";
import { hexToBytes } from "@ethereumjs/util";

async function gasEstimate(reward_contract: any, provider: any, user: string) {
  try {
    const gas_estimate =
      3n * (await reward_contract.reward.estimateGas(user, 0n));
    const feeData = await provider.getFeeData();
    const maxFeePerGas =
      feeData.maxFeePerGas ?? ethers.parseUnits("50", "gwei");
    const maxPriorityFeePerGas =
      feeData.maxPriorityFeePerGas ?? ethers.parseUnits("2", "gwei");
    return [gas_estimate, maxFeePerGas, maxPriorityFeePerGas];
  } catch (error) {
    console.log(error);
  }
  return [
    142584n,
    ethers.parseUnits("50", "gwei"),
    ethers.parseUnits("2", "gwei")
  ];
}

export async function runTransaction(
  provider: any,
  ad: string,
  ca0: string,
  ca1: string,
  amount: number,
  reward_contract: ethers.Contract,
  signer: JsonRpcSigner,
  window_ethereum: any
) {
  // await reward_contract.reward(ca0, ca1, 0);

  const [gas_estimate, maxFeePerGas, maxPriorityFeePerGas] = await gasEstimate(
    reward_contract,
    provider,
    ad
  );

  const tx = signer.populateTransaction({
    to: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    value: "0x0"
  });
  const auth = await populateAndSignAuthAddress(ca1, ad, signer, provider);
  const transactionCount = await provider.getTransactionCount(ad);
  const commonWithCustomChainId = createCustomCommon(
    { chainId: auth.chainId },
    Mainnet,
    {
      eips: [7702],
      hardfork: Hardfork.Cancun
    }
  );
  const call_data = new ethers.Interface(
    helperApproveAndSwap.abi
  ).encodeFunctionData("batchReward", [ca0, ca1, BigInt(amount)]);
  const tx1 = createEOACode7702Tx(
    {
      authorizationList: [auth],
      to: ad as any,
      gasLimit: gas_estimate,
      nonce: BigInt(transactionCount),
      maxFeePerGas: maxFeePerGas as bigint,
      maxPriorityFeePerGas: maxPriorityFeePerGas as bigint,
      data: hexToBytes(call_data as any)
    },
    { common: commonWithCustomChainId }
  );
  // signer.sendTransaction()
  const txHash = await window_ethereum.request({
    method: 'eth_sendTransaction',
    params: [tx1],
  });
  await txHash.wait();
}
