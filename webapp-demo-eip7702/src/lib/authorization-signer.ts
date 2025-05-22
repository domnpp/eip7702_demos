import {type Wallet, type Provider, encodeRlp, decodeRlp, keccak256, JsonRpcSigner, Signature} from 'ethers'
// import {EOACode7702AuthorizationList} from '@ethereumjs/common'
// import {EOACode7702AuthorizationListItem} from '@ethereumjs/common'
// import {EOACode7702AuthorizationListItemUnsigned} from '@ethereumjs/common'
import {EIP7702} from './configs'
import {bigIntToBytes, bigIntToHex, bytesToHex, hexToBytes, ecrecover} from '@ethereumjs/util'
import { ecsign, toBuffer } from 'ethereumjs-util';


const populateAndSignAuthAddress = async (
	address: string,
	wallet_address: string,
	signer: JsonRpcSigner,
	provider: Provider,
): Promise<any> => {
	const nonce = BigInt(await provider.getTransactionCount(wallet_address, 'pending'))
	const {chainId} = await provider.getNetwork()
	const magicBuffer = Buffer.from([EIP7702.MAGIC])
	const rlpData = encodeRlp([bigIntToBytes(chainId),
	 hexToBytes(address as any), bigIntToBytes(nonce)])
	const signBytes = Buffer.concat([magicBuffer, hexToBytes(rlpData as any)]);
	const hash: any = keccak256(signBytes);
	// const signature = ecsign(toBuffer(hexToBytes(hash)), toBuffer(hexToBytes(wallet.privateKey)));
	const signature = await signer.signMessage(hash);
	const parsed = Signature.from(signature);
	return {
		address: address as `0x${string}`,
		chainId: bigIntToHex(chainId),
		nonce: bigIntToHex(nonce) === '0x0' ? '0x' : bigIntToHex(nonce),
		r: parsed.r,
		s: parsed.s,
		yParity: bigIntToHex(BigInt(parsed.v - 27)) === '0x0' ? '0x' : '0x1',
	}
}

export {populateAndSignAuthAddress}
