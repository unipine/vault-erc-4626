import * as React from 'react';
import { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet-async';
import { ethers } from 'ethers';
import Web3Modal from 'web3modal';
import WalletConnectProvider from '@walletconnect/web3-provider';
//import { Button } from 'web3uikit';

const providerOptions = {
  walletconnect: {
    package: WalletConnectProvider,
    options: {
      infuraId: process.env.INFURA_ID,
    }
  }
};

const web3Modal = new Web3Modal({
  network: "mainnet", // optional
  cacheProvider: true, // optional
  providerOptions // required
});

async function getProvider(setProvider) {
  const instance = await web3Modal.connect();
  const provider = new ethers.providers.Web3Provider(instance);
  setProvider(provider);
}


export function HomePage() {
  const [provider, setProvider] = useState<ethers.providers.Web3Provider | undefined>(undefined);
  return (
    <>
      <Helmet>
        <title>HomePage</title>
        <meta name="description" content="A Boilerplate application homepage" />
      </Helmet>
      <span>My HomePage</span>
    </>
  );
}
