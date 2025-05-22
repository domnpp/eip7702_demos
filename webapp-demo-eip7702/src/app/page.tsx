"use client";

import Image from "next/image";
import { useEffect, useState } from "react";
import { BrowserProvider, ethers, JsonRpcSigner } from "ethers";
import deployed from "../lib/contracts.json";

const ABI_ERC20 = [
  "error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed)",
  "error ERC20InvalidSender(address sender)",
  "error ERC20InvalidReceiver(address receiver)",
  "error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed)",
  "error ERC20InvalidApprover(address approver)",
  "error ERC20InvalidSpender(address spender)",
  "function balanceOf(address account) external view returns (uint256)"
];

const ABI0 = ABI_ERC20.concat([
  "function mint(address to, uint256 amount) external"
]);
const ABI1 = ABI_ERC20.concat([
  "function reward(address to, uint256 amount) external"
]);

let g_p: BrowserProvider;
let g_s: JsonRpcSigner;
let g_ca0: any;
let g_ca1: any;

export default function Home() {
  const [balance_0, setBalance0] = useState<number>(0);
  const [balance_1, setBalance1] = useState<number>(0);
  const [account, setAccount] = useState<string>("");
  const [tokensCa, setTokensCa] = useState<string[]>([]);
  const [choice_0, setChoice0] = useState<number>(0);
  const [choice_1, setChoice1] = useState<number>(0);
  // const [payTransaction, setPayTransaction] = useState<any>(null);

  useEffect(() => {
    if (typeof window.ethereum === "undefined") {
      return;
    }
    window.ethereum
      .request({ method: "eth_accounts" })
      .then(async (accounts: any) => {
        if (accounts.length) {
          if (accounts[0] == account) {
            return;
          }
          console.log(`You're connected to: ${accounts[0]}`);
          setAccount(accounts[0]);
          setTokensCa([deployed.SourceTok, deployed.RewardTok]);
          g_p = new ethers.BrowserProvider(window.ethereum);
          g_s = await g_p.getSigner();

          g_ca0 = new ethers.Contract(deployed.SourceTok, ABI0, g_s);
          g_ca1 = new ethers.Contract(deployed.RewardTok, ABI1, g_s);
          g_ca0.balanceOf(accounts[0]).then((n: bigint) => {
            setBalance0(Number(n));
          });
          g_ca1.balanceOf(accounts[0]).then((n: bigint) => {
            setBalance1(Number(n));
          });
          console.log("Smart contracts prepared successfully.");
        } else {
          console.log("Metamask is not connected");
        }
      });
  }, [account]);

  async function connectWallet() {
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.BrowserProvider(window.ethereum);
      // Should throw if issues.
      provider.send("eth_requestAccounts", []);
      // Set fake string to trigger useEffect that will get the actual value.
      setAccount("⏳");
    } else {
      alert("MetaMask not detected");
    }
  }

  const _onClickMint = () => {
    g_ca0.mint(account, choice_0).then(
      async (tx: any) => {
        await tx.wait();
        g_ca0.balanceOf(account).then((n: bigint) => {
          setBalance0(Number(n));
        });
      },
      (error: any) => {
        alert("Mint call failed! ");
        console.log("Mint call failed! ", error);
      }
    );
  };

  const _onClickSwap = () => {
    g_ca1.reward(account, choice_1).then(
      async (tx: any) => {
        await tx.wait();
        g_ca1.balanceOf(account).then((n: bigint) => {
          setBalance1(Number(n));
        });
      },
      (error: any) => {
        if (error.hasOwnProperty("data") && error.data)
        {
          const parsed = g_ca1.interface.parseError(error.data);
          console.log("Parsed it well;");
          alert("Error: " + parsed.name);
        }
        else
        {
          alert("Reward call failed! ");
          console.log("Mint call failed! ", error);
        }
      }
    );
  };

  return (
    <div className="grid grid-rows-[20px_1fr_20px] min-h-screen items-center justify-items-center font-[family-name:var(--font-geist-sans)]">
      <main className="flex min-w-[640px] flex-col row-start-2 items-center w-full">
        <div className="flex min-w-[640px] flex-col gap-[16px] row-start-2 items-center">
          <div className="w-full min-w-[640px] flex gap-4 items-center flex-col sm:flex-row">
            <button
              className="pr-4 rounded-full w-fit border border-solid border-transparent transition-colors flex items-center justify-center bg-foreground text-background gap-2 hover:bg-[#383838] dark:hover:bg-[#ccc] font-medium text-sm sm:text-base h-10 gui_elem_h"
              rel="noopener noreferrer"
              disabled={account.length > 1}
              onClick={connectWallet}
            >
              <Image
                className="dark:invert"
                src="/crypto-wallet-svgrepo-com.svg"
                alt="Vercel logomark"
                width={32}
                height={32}
              />
              Connect wallet
            </button>

            <label className="text-sm sm:text-base w-auto shrink-0">
              Addr:
            </label>
            <input
              readOnly
              value={account}
              placeholder="Connected address"
              className="w-full h-10 gui_elem_h px-4 sm:px-5 text-sm sm:text-base rounded-full border border-solid border-foreground bg-background text-foreground placeholder-gray-400 dark:placeholder-gray-600 focus:outline-none focus:ring-2 focus:ring-[#383838] dark:focus:ring-[#ccc] transition-colors"
            />
          </div>

          <div className="w-full flex gap-4 items-center flex-col sm:flex-row">
            <div className="w-full h-10 gui_elem_h px-4 sm:px-5 text-sm sm:text-base rounded-full border border-solid border-foreground bg-background text-foreground flex items-center">
              Currency balance:{" "}
              <span className="ml-2 font-medium text-green-600 dark:text-green-400">
                {balance_0}
              </span>
            </div>

            <div className="w-full h-10 gui_elem_h px-4 sm:px-5 text-sm sm:text-base rounded-full border border-solid border-foreground bg-background text-foreground flex items-center">
              Reward balance:{" "}
              <span className="ml-2 font-medium text-green-600 dark:text-green-400">
                {balance_1}
              </span>
            </div>
          </div>
          <div className="w-full flex gap-4 items-center flex-col sm:flex-row">
            <input
              type="number"
              step="0.01"
              placeholder="Enter amount"
              value={choice_0}
              onChange={(e) => setChoice0(Number(e.target.value))}
              className="w-full h-10 gui_elem_h px-4 sm:px-5 text-sm sm:text-base rounded-full border border-solid border-foreground bg-background text-foreground placeholder-gray-400 dark:placeholder-gray-600 focus:outline-none focus:ring-2 focus:ring-[#383838] dark:focus:ring-[#ccc] transition-colors"
            />

            <button
              className="w-full rounded-full border border-solid border-transparent transition-colors flex items-center justify-center bg-foreground text-background gap-2 hover:bg-[#383838] dark:hover:bg-[#ccc] font-medium text-sm sm:text-base h-10 gui_elem_h px-4 sm:px-5"
              rel="noopener noreferrer"
              onClick={_onClickMint}
            >
              <Image
                className="dark:invert"
                src="/vercel.svg"
                alt="Vercel logomark"
                width={20}
                height={20}
              />
              Mint (free)
            </button>
          </div>

          <div className="w-full flex gap-4 items-center flex-col sm:flex-row">
            <input
              type="number"
              step="0.01"
              placeholder="Enter amount"
              value={choice_1}
              onChange={(e) => setChoice1(Number(e.target.value))}
              className="w-full h-10 gui_elem_h px-4 sm:px-5 text-sm sm:text-base rounded-full border border-solid border-foreground bg-background text-foreground placeholder-gray-400 dark:placeholder-gray-600 focus:outline-none focus:ring-2 focus:ring-[#383838] dark:focus:ring-[#ccc] transition-colors"
            />

            <button
              className="w-full rounded-full border border-solid border-transparent transition-colors flex items-center justify-center bg-foreground text-background gap-2 hover:bg-[#383838] dark:hover:bg-[#ccc] font-medium text-sm sm:text-base h-10 gui_elem_h px-4 sm:px-5"
              rel="noopener noreferrer"
              onClick={_onClickSwap}
            >
              <Image
                className="dark:invert"
                src="/vercel.svg"
                alt="Vercel logomark"
                width={20}
                height={20}
              />
              Swap (EIP7702)
            </button>
          </div>
        </div>
      </main>

      <footer className="row-start-3 mt-16 flex gap-[24px] flex-wrap items-center justify-center">
        <a
          className="flex items-center gap-2 hover:underline hover:underline-offset-4"
          href="https://nextjs.org/learn?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Image
            aria-hidden
            src="/file.svg"
            alt="File icon"
            width={16}
            height={16}
          />
          Learn
        </a>
      </footer>
    </div>
  );
}
