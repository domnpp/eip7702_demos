import {
  createPublicClient,
  createWalletClient,
  encodeFunctionData,
  http,
  parseAbi,
  parseEther
} from "viem";
import { anvil } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const HARDCODED_SK =
  "0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e";

export async function swapPectraPrague(
  balance_abi: string[],
  account: string,
  sz: bigint,
  currency: string,
  reward: string,
  reward_ca: any,
  helper_ca: string,
  helper_abi: any
) {
  const walletClient = createWalletClient({
    account: account as `0x${string}`,
    chain: anvil,
    transport: http()
  });
  const eoa = privateKeyToAccount(HARDCODED_SK);
  // 1. Authorize designation of the Contract onto the EOA.
  const authorization = await walletClient.signAuthorization({
    account: eoa,
    contractAddress: helper_ca as `0x${string}`,
    executor: "self"
  });

  // 2. Designate the Contract on the EOA, and invoke the function.
  const hash = await walletClient.sendTransaction({
    account: eoa,
    authorizationList: [authorization],
    data: encodeFunctionData({
      abi: helper_abi,
      functionName: "batchReward",
      args: [currency, reward, sz]
    }),
    to: walletClient.account.address
  });

  const publicClient = createPublicClient({
    chain: anvil,
    transport: http()
  });
  const abi = parseAbi(balance_abi);

  const balances_after = await Promise.all([
    publicClient.readContract({
      address: reward as any,
      abi: abi,
      functionName: "balanceOf",
      args: [account]
    }),
    publicClient.readContract({
      address: currency as any,
      abi: abi,
      functionName: "balanceOf",
      args: [account]
    })
  ]);
  console.log(`After: ${balances_after[1]} money, ${balances_after[0]} rewards.`);

  return {hash, c: balances_after[1], r: balances_after[0]};
}
