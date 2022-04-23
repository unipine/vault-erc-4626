import { Layout, Divider, Row, Col, Input, notification } from 'antd';

const { Header, Footer, Sider, Content } = Layout;

import Head from 'next/head'
import Image from 'next/image'
import styles from '../styles/Home.module.css'
import { Button, ConnectButton, CryptoLogos } from 'web3uikit'
import { useMoralis, useWeb3Contract } from 'react-moralis'
import { Moralis } from 'moralis'
import { ethers } from 'ethers'
import { useState, useEffect } from 'react'

async function updateBalances(account, setNative, setVault) {
  let provider = ethers.getDefaultProvider();
  let nativeBalance = await provider.getBalance(account);
  nativeBalance = ethers.utils.formatEther(nativeBalance)
  try {
    const web3Provider = await Moralis.enableWeb3();
  } catch (e) {
    return;
  }
  let abi = [];
  let contract = new ethers.Contract('', abi, provider);
  let vaultBalance = 0;
  try {
    vaultBalance = await contract.maxWithdraw(account);
  } catch (e) {
    vaultBalance = 0;
  }
  vaultBalance = ethers.utils.formatEther(vaultBalance)
  setNative(nativeBalance);
  setVault(vaultBalance);
}

export default function Home() {
  const { authenticate, isAuthenticated, isAuthenticating, user, account, logout } = useMoralis();
  const { data, error, runContractFunction, isFetching, isLoading, } = useWeb3Contract();
  const [nativeBalance, setNative] = useState(0);
  const [vaultBalance, setVault] = useState(0);
  const [depositValue, setDepositValue] = useState(0);
  const [withdrawalValue, setWithdrawalValue] = useState(0);
  useEffect(() => {
    if(account != null) {
      updateBalances(account, setNative, setVault);
    }
  });
  return (
    <div className={styles.container}>
      <Head>
        <title>PPP</title>
        <meta name="description" content="lfg" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div className={styles.sidenav}>
        <Row>
          <Col>
            <h1 className={styles.logo}>ARB</h1>
            <ConnectButton className={styles.addressview} />
          </Col>
          <Divider style={{ margin: "10px" }}></Divider>
          <Col>
            <div className={styles.buttoner} style={{ position: "fixed", bottom: "10px", left: "10px" }}>

              <Button
                theme='outline'
                id='infobutton'
                onClick={() => location.href = 'https://google.com'}
                text='Read More'
                type='button'
                icon="externalLink"
                className={styles.buttoner}
              />
            </div>
          </Col>
        </Row>
      </div>
      <main className={styles.main}>
        <div className={styles.module}>
          <h1 className={styles.text}>Market Make like the Pros</h1>
          <h3 className={styles.text} style={{fontWeight: "normal", marginTop: "-10px"}}>Your Home for Trading Power Perpetuals</h3>

          <div style={{ display: 'grid', gap: '20px', padding: '40px 20px' }}>
            <section style={{ display: 'flex', gap: '20px'}}>
              <div style={{ borderRadius: '25px', textAlign: "center", width: "100%", background: `linear-gradient( rgba(0, 0, 0, 0.6), rgba(0, 0, 0, 0.6) ), url("bear.png")`, backgroundSize: 'contain', padding: "40px", border: "2px solid #F1559B", marginTop: "-30px"}}>
                <h2 style={{fontSize:"32px", marginTop: "-12px"}}>Bearish</h2>
                <i style={{marginTop:"-12px"}}>~Continuously mint and short squeeth while maintaining collateral ratio~</i>
                <div style={{ borderRadius: '25px', backgroundColor: "#F1559BD0", padding: "5px", width: "40%", margin: "auto", marginBottom: "12px", marginTop: "10px"}}>
                  <b>Your Balance</b>
                  <p style={{marginTop: "-3px"}}>{nativeBalance} ETH</p>
                </div>
                <section style={{ display: 'flex', gap: '20px', marginBottom: "12px"}}>
                  <div style={{ borderRadius: '25px', backgroundColor: "#90afc9D0", border: "1px solid black", width: "50%", textAlign: "center", display: 'flex', alignItems: "center", marginLeft: "10px", padding: "7px"}}>
                    <div style={{padding: "6px"}}>
                    <p style={{fontSize: "small"}}>Available: {nativeBalance} ETH.</p>
                    <Input id="deposit-input"
                      defaultValue='0.0'
                      placeholder='0.0'
                      onChange={(e) => { setDepositValue(e.target.value) }}
                      type="number"
                    />
                    </div>
                    <div className={styles.buttoner} style={{right: "-200%"}}>
                      <Button
                        theme='outline'
                        id='infobutton'
                        onClick={async () => {
                          const web3Provider = await Moralis.enableWeb3();
                          let provider = ethers.getDefaultProvider();
                          let abi = []
                          const signer = web3Provider.getSigner();
                          let contract = new ethers.Contract('', abi, signer);
                          const options = { value: ethers.utils.parseEther(depositValue.toString()) }
                          console.log(depositValue.toString(), options)
                          try {
                            let currentValue = await contract.deposit(options);
                          } catch (e) {
                            notification.open({
                              description: `you don't have ${depositValue.toString()} ETH lmfao. is this a joke?`,
                              duration: 1
                            });
                          }
                          updateBalances(account, setNative, setVault);

                        }}
                        text='Deposit'
                        type='button'
                        icon="arrowCircleRight"
                        className={styles.buttoner}
                        disabled={account == null}
                      />
                    </div>
                  </div>
                  <div style={{ borderRadius: '25px', padding: "8px", width: "50%", backgroundColor: "#90afc9D0", textAlign: "center", display: 'flex', alignItems: "center", border: "1px solid black" }}>
                    <div style={{float: "left", padding: "6px"}}>
                    <p style={{fontSize: "small"}}>Available: {vaultBalance} ETH.</p>
                    <Input id="withdrawal-input"
                      defaultValue='0.0'
                      placeholder='0.0'
                      onChange={(e) => { setWithdrawalValue(e.target.value) }}
                      type="number"

                    />
                    </div>
                    <div className={styles.buttoner} style={{right: "-200%"}}>
                      <Button
                        theme='outline'
                        id='infobutton'
                        onClick={async () => {
                          const web3Provider = await Moralis.enableWeb3();
                          let provider = ethers.getDefaultProvider();
                          let abi = []
                          const signer = web3Provider.getSigner();
                          let contract = new ethers.Contract('', abi, signer);
                          console.log(withdrawalValue.toString())
                          try {
                            let currentValue = await contract.withdraw(withdrawalValue.toString(), address, address);
                          } catch (e) {
                            notification.open({
                              description: `you don't have ${withdrawalValue.toString()} ETH in the valut.`,
                              duration: 1
                            });
                          }
                          updateBalances(account, setNative, setVault);

                        }}
                        text='Withdraw'
                        type='button'
                        icon="arrowCircleLeft"
                        className={styles.buttoner}
                        disabled={account == null}
                      />
                    </div>
                  </div>
                </section>
                <div style={{ borderRadius: '25px', backgroundColor: "#F1559BD0", padding: "5px", width: "40%", margin: "auto", marginBottom: "12px"}}>
                  <p>Total Value Deposited 0 ETH</p>
                  <p>7D Performace 0%</p>
                  <p>28D Performance 0%</p>
                </div>
              </div>
            </section>
            <section style={{ display: 'flex', gap: '20px' }}>
              <div style={{ borderRadius: '25px', backgroundColor: "red", width: "50%", textAlign: "center", backgroundImage: `url("bull.png")`, backgroundSize: 'contain' }}>
                <h2>Bullish</h2>
                <h3>(Coming Soon)</h3>
              </div>
              <div style={{ borderRadius: '25px', backgroundColor: "red", width: "50%", textAlign: "center", backgroundImage: `url("hedge.jpeg")`, backgroundSize: 'contain' }}>
                <h2>Hedge</h2>
                <h3>(Coming Soon)</h3>
              </div>
            </section>
          </div>
        </div>
        <div>
          <img src={"https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Copyleft.svg/1920px-Copyleft.svg.png"} style={{ height: "10px", marginTop: "26px", float: "left" }} />
          <h5 style={{ float: "right" }}>&nbsp;2022 Katan Ralianio.</h5>
        </div>
      </main>
    </div>
  );
}