import React, { useState, useEffect } from 'react';
import $ from 'jquery';
import './index.css';
import {useHistory} from 'react-router-dom';
import { controlPot } from '../../contractConstant';
import Web3 from 'web3';
import detectEthereumProvider from '@metamask/detect-provider';
import BigNumber from "bignumber.js";
import fs from 'fs';
import jsonData from '../../contractConstant.json';
import Dropdown from 'react-dropdown';

const Tournament = (props) => {
    const [pairAddress, setPairAddress] = useState("");

    const [topOwnerFee, setTopOwnerFee] = useState(0);
    const [potFee, setPotFee] = useState(0);
    const [toPreviousFee, setToPreviousFee] = useState(0);

    // expiry time
    const [expVariable1, setExpVariable1] = useState(0);
    const [expVariable2, setExpVariable2] = useState(0);
    const [expVariable3, setExpVariable3] = useState(0);

    // bidAmount
    const [bidVariable1, setBidVariable1] = useState(0);
    const [bidVariable2, setBidVariable2] = useState(0);

    // Create tournament    
    const [selectedBidOption, setSelectedBidOption] = useState('');
    const [selectedPrioriyPoolOption, setSelectedPrioriyPoolOption] = useState('');
    const [selectedExpireTimeOption, setSelectedExpireTimeOption] = useState(''); 
    const [selectedPotToken, setSelectedPotToken] = useState(0); 
    const [selectedBidToken, setSelectedBidToken] = useState(0); 
    
    // token list
    const [tokenList, setTokenList] = useState({});

    const [tempAddAddress, setTempAddAddress] = useState('');   
    const [distributionAddress, setDistributionAddress] = useState({
        "address": []
    });
    const history = useHistory();
    const [web3Instance, setWeb3Instance] = useState('');
    const [currentAddress, setCurrentAddress] = useState('');
    const [potContract, setPotContract] = useState([]);

    const [potAmount, setPotAmount] = useState(0);
   
    let defaultOption;

    const connectMetamask = async () => {
        try {
          let currentProvider = await detectEthereumProvider();
          if (currentProvider) {
            let web3InstanceCopy = new Web3(currentProvider);
            setWeb3Instance(web3InstanceCopy);
            if (!window.ethereum.selectedAddress) {
              await window.ethereum.request({ method: 'eth_requestAccounts' });
            }
            await window.ethereum.enable();
            let currentAddress = window.ethereum.selectedAddress;
            const currentChainId = await window.web3.eth.net.getId()
            if (currentChainId !== 80001) {
                try {
                    await window.ethereum.request({
                    method: 'wallet_switchEthereumChain',
                    params: [{ chainId: Web3.utils.toHex(80001) }],
                    });
                    setCurrentAddress(currentAddress);
                } catch (switchError) {
                }
            } else {
                setCurrentAddress(currentAddress);
                console.log(currentAddress);
            }
          }
        } catch (err) {
            alert(err.message)
        }
    }
    const loadWeb3 = async () => {
        if (window.ethereum) {
            window.web3 = new Web3(window.ethereum);
            window.ethereum.enable();
        }
    }
    const disconnect = async () => {
        await window.ethereum.request({
            method: "wallet_requestPermissions",
            params: [
                {
                    eth_accounts: { currentAddress }
                }
            ]
        });
    }
    const loadContract = async () => {
        const ABI = controlPot.ABI;
        const contractAddress = controlPot.contractAddress;
        return await new window.web3.eth.Contract(ABI, contractAddress);
    }    
    useEffect(() => {
        const effect = async () => {
            await loadWeb3();          
            let _contract = await loadContract();
            let _topOwnerFee = await _contract.methods.toOwnerFee().call();
            let _tokenList = await _contract.methods.getTokenList().call();
            console.log(tokenList);
            setTopOwnerFee(_topOwnerFee);
            setTokenList(
                _tokenList.map((item, key) => {
                    return { value: key, label: item }
                })
            )
            await setPotContract(_contract);
        }
        effect();        
    }, [distributionAddress]);

    const createTournament = async () => {
        if(currentAddress != 0) {
            let isNative = false;
            console.log(jsonData.NativeToken);
            if(tokenList[selectedPotToken]["label"] == jsonData.NativeToken) {
                isNative = true;
            }
            let createTournamentAmount;
            let totalAmount;
            createTournamentAmount = selectedPrioriyPoolOption * 10000000000000000;
            totalAmount = Number(createTournamentAmount) + Number(potAmount);
            let amount = new BigNumber(String(totalAmount));
            let toAddress = [];        
            let toPercent = [];
            let priorityPool = 0;
            if(selectedPrioriyPoolOption == 0.01) {
                priorityPool = false;
            } else {
                priorityPool = true;
            }

            distributionAddress.address.map((item) => {
                toAddress.push(item.distributionAddress);
                toPercent.push(item.distributionValue);
            });
            const createNumber = Date.now();
            console.log(createNumber);
            const arrayDatas =  [potFee, toPreviousFee, createNumber];
            let expirationTime = [selectedExpireTimeOption, expVariable1,expVariable2,expVariable3];
            let bidAmount = [selectedBidOption, bidVariable1, bidVariable2];
            let pair = await potContract.methods.createPot(selectedPotToken, isNative, potAmount, selectedBidToken, bidAmount, toAddress, toPercent, expirationTime, priorityPool, arrayDatas)
            .send({
                from: currentAddress,
                value: BigNumber(createTournamentAmount)
            }, function(error, tokens){
                console.log(tokens); 
            });
            let tempPairAddress = 0;
            tempPairAddress = pair.events.Deployed.returnValues[0];
            setPairAddress(tempPairAddress);
        } else {
            alert("please connect metamsk");
        }
    }

    const handleChangeBidOption = (value) => {
        setSelectedBidOption(value);
    }
    const handleExpireTime = (value) => {
        setSelectedExpireTimeOption(value);
    }
    const handlePriorityPool = (value) => {
        setSelectedPrioriyPoolOption(value);
    }

    const addDistributionAddress = () => {
        const newItem = {
            "distributionValue": 0,
            "distributionAddress": tempAddAddress,
        }    
        let temp = {
            "address": []
        }
        temp = { "address": temp['address'] ? [...distributionAddress['address'], newItem] : [newItem] }
        setDistributionAddress(temp);
        setTempAddAddress("");
    }
    const handleChangeDistributionAddress = (value, key) => {
        let temp = {...distributionAddress}
        temp.address[key]['distributionValue'] = value
        console.log(temp);
        setDistributionAddress(temp);
    }
    const handleChangeBidTokenOption = (value) => {
        setSelectedBidToken(value);
    }
    const depositToken = async () => {        
        let potABI = jsonData.contractABI;
        // let _potContract = await new window.web3.eth.Contract(potABI, "0xAc0DDd7A1f19bD36606822424919c12Acce5EECD");
        let _potContract = await new window.web3.eth.Contract(potABI, pairAddress);
        let potToken = await _potContract.methods.potToken().call();
        if(potToken == jsonData.NativeToken) {
            let value = Number(potAmount);
            await _potContract.methods.depositToken()
            .send({
                from: currentAddress,
                value: BigNumber(value)
            }, function(error, tokens){
                console.log(tokens);
            });
        } else {
            let _erc20Contract = await new window.web3.eth.Contract(jsonData.ERC20ABI, potToken);
            await _erc20Contract.methods.approve(pairAddress, BigNumber(Number(potAmount)).toFixed().toString()).send({ from: currentAddress });
            await _potContract.methods.depositERC20Token()
            .send({
                from: currentAddress
            }, function(error, tokens){
                console.log(tokens); 
            });
        }
    }
    const onPotTokenSelect = (e) => {        
        console.log(e.value);
        setSelectedPotToken(e.value);
    }
    const onBidTokenSelect = (e) => {
        console.log(e);
        setSelectedBidToken(e.value);
    }
    return (
        <div className='pt-3 m-auto d-flex justify-content-center'>
            <div>
                <div className="d-flex justify-content-between"><p className='pt-3 font-bold mb-0'>Create tournament</p>
                {pairAddress != "" && (<div className="btn btn-primary" onClick={depositToken}>Deposit</div>)}
                {/* <div className="btn btn-primary" onClick={depositToken}>Deposit</div> */}
                {currentAddress == "" && (<div className='btn btn-warning ml-3' onClick={connectMetamask}>Connect</div>)}
                {currentAddress != "" && (<div className='btn btn-warning ml-3' onClick={disconnect}>{currentAddress}</div>)}
                
                </div>
                <div>
                    <p className='mb-0'>Choose pot token</p>
                    <div className='select'>List of allowed tokens</div>
                    {/* <div className='bg-red mt-3'>{tokenList.map((item, key) => {return <div className='d-flex'><input type='radio' value={key} checked={selectedPotToken == key} onChange={(e) => handleChangePotTokenOption(e.target.value)}/><div className='ml-1'>{item}</div></div>})}</div> */}
                    <Dropdown options={tokenList} onChange={(e) => onPotTokenSelect(e)} value={defaultOption} placeholder="Select an pot Token" />
                    <div className='d-flex pt-2'>
                        <p className='align-self-center mb-0 pr-3'>Pot amount</p>
                        <input type='text' className='form form-control form-custom' value={potAmount} onChange={(e) => setPotAmount(e.target.value)} /> uint256
                    </div>
                    <div className='pt-4'>
                        <p className='mb-0'>Choose bid token</p>
                        <div className='select'>List of allowed tokens</div>
                    </div>
                    <Dropdown options={tokenList} onChange={(e) => onBidTokenSelect(e)} value={defaultOption} placeholder="Select an bid Token" />
                    <div className='pt-4'>
                        <p className='mb-0'>Bid price</p>
                        <form>
                            <div className='d-flex'>
                                <input type='radio' value="0" checked={selectedBidOption == "0"} onChange={(e) => handleChangeBidOption(e.target.value)}/>
                                <p className='mb-0 align-self-center px-2'>Fixed</p>
                                <input type='text' className='form form-control form-custom' value={bidVariable1} disabled={selectedBidOption !== "0"} onChange={(e) => setBidVariable1(e.target.value)} />
                            </div>
                            <div className='d-flex py-2'>
                                <input type='radio' value="1" checked={selectedBidOption == "1"} onChange={(e) => handleChangeBidOption(e.target.value)}/>
                                <p className='mb-0 align-self-center px-2'>% of current pot</p>
                                <input type='text' className='form form-control form-custom' value={bidVariable1} disabled={selectedBidOption !== "1"}  onChange={(e) => setBidVariable1(e.target.value)} />
                            </div>
                            <div className='d-flex py-2'>
                                <input type='radio' value="2" checked={selectedBidOption == "2"} onChange={(e) => handleChangeBidOption(e.target.value)}/>
                                <p className='mb-0 align-self-center px-2'>increase with a multiplier after every bid.</p>
                            </div>
                            <div className='px-5'>
                                <div className='d-flex justify-content-between py-1'>
                                    <p className='align-self-center mb-0 pr-3'>Start amount</p>
                                    <input type='text' className='form form-control form-custom' value={bidVariable1} disabled={selectedBidOption !== "2"} onChange={(e) => setBidVariable1(e.target.value)} />
                                </div>
                                <div className='d-flex justify-content-between py-1'>
                                    <p className='align-self-center mb-0 pr-3'>Increase by</p>
                                    <input type='text' className='form form-control form-custom' value={bidVariable2} disabled={selectedBidOption !== "3"} onChange={(e) => setBidVariable2(e.target.value)} />
                                </div>
                            </div>                        
                        </form>

                        <div className='pt-5'>
                            <p>Set bid price distribution</p>
                            <div className='d-flex justify-content-between py-1'>
                                <p className='mb-0'>TopOwner</p>
                                <div className='select'>{topOwnerFee}%</div>
                            </div>
                            <div className='d-flex justify-content-between py-1'>
                                <p className='mb-0 align-self-center'>OwnerOfTournament</p>
                                <input type='text' className='form form-control form-custom-25' value={potFee} onChange={(e) => setPotFee(e.target.value)} />% value
                            </div>
                            <div className='d-flex justify-content-between py-1'>
                                <p className='mb-0 align-self-center'>Previous bidder</p>
                                <input type='text' className='form form-control form-custom-25' value={toPreviousFee} onChange={(e) => setToPreviousFee(e.target.value)} />% value
                            </div>
                            
                            {distributionAddress.address.map((item, key) => {
                                return (
                                <div className='d-flex justify-content-between py-1' key={key}>
                                    <p className='mb-0 align-self-center'>Add {key + 1}</p>
                                    <input type='text' className='form form-control form-custom-25' value={item.distributionValue} onChange={(e) => handleChangeDistributionAddress(e.target.value, key)}/>
                                    <input  type='text' className='form form-control form-custom-100' value={item.distributionAddress} disabled/>
                                </div>
                            )})}
                            <div className='py-1'>
                                <div className='select' onClick={addDistributionAddress} >Add another address</div>
                                <input  type='text' className='form form-control mt-2 form-custom-100' value={tempAddAddress} onChange={(e) => setTempAddAddress(e.target.value)}/>
                            </div>
                        </div>
                        <div className='pt-5'>
                            <p className='mb-0'>Expire Time</p>
                            <div className='d-flex'>
                                <input type='radio' value="1" checked={selectedExpireTimeOption == "1"} onChange={(e) => handleExpireTime(e.target.value)} />
                                <p className='mb-0 align-self-center px-2'>Fixed</p>
                                <input type='text' className='form form-control form-custom' disabled={selectedExpireTimeOption !== "1"} value={expVariable1} onChange={(e)=> setExpVariable1(e.target.value)}/>
                            </div>
                            <div className='d-flex py-2'>
                                <input type='radio' value="2" checked={selectedExpireTimeOption == "2"} onChange={(e) => handleExpireTime(e.target.value)} />
                                <p className='mb-0 align-self-center px-2'>Decreasing</p>
                            </div>
                            <div className='px-5'>
                                <div className='d-flex justify-content-between py-1'>
                                    <p className='align-self-center mb-0 pr-3'>Start time</p>
                                    <input type='text' className='form form-control form-custom' value={expVariable1} disabled={selectedExpireTimeOption !== "2"} onChange={(e)=> setExpVariable1(e.target.value)}/> seconds
                                </div>
                                <div className='d-flex justify-content-between py-1'>
                                    <p className='align-self-center mb-0 pr-3'>Decrease by</p>
                                    <input type='text' className='form form-control form-custom' value={expVariable2} disabled={selectedExpireTimeOption !== "2"} onChange={(e)=> setExpVariable2(e.target.value)} /> seconds
                                </div>
                                <div className='d-flex justify-content-between py-1'>
                                    <p className='align-self-center mb-0 pr-3'>Minimum Time</p>
                                    <input type='text' className='form form-control form-custom' value={expVariable3} disabled={selectedExpireTimeOption !== "2"} onChange={(e)=> setExpVariable3(e.target.value)} /> seconds
                                </div>
                            </div>
                        </div>
                        <div className='pt-5'>
                            <p className='mb-0'>Priority pool</p>
                            <form>
                                <div className='d-flex'>
                                    <input type='radio' value={0.01} checked={selectedPrioriyPoolOption == 0.01} onChange={(e) => handlePriorityPool(e.target.value)} />
                                    <p className='mb-0 align-self-center px-2'>Yes (Costs 0.01 MATIC)</p>
                                </div>
                                <div className='d-flex py-2'>
                                    <input type='radio' value={0.02} checked={selectedPrioriyPoolOption == 0.02} onChange={(e) => handlePriorityPool(e.target.value)} />
                                    <p className='mb-0 align-self-center px-2'>No (Costs 0.02 MATIC)</p>
                                </div>
                            </form>
                        </div>
                        <div className='text-center py-4'>
                            <div className='select' onClick={createTournament} >Create torunament</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

export default Tournament;