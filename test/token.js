const Token = artifacts.require('MoonwhaleToken');
import BigNumber  from 'bignumber.js';
import latestTime from './helpers/latestTime.js'
import ether from './helpers/ether.js';
import {increaseTimeTo, duration} from './helpers/increaseTime'
require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

contract('Token', async function(accounts) {
  describe('Token Creation', async () => {
    it('should deploy with correct parameters', async () => {
      const gameficationWallet = accounts[1];
      const owner = accounts[0];
      const token = await Token.new(gameficationWallet);
      const creationTime = latestTime();
      const INITIAL_SUPPLY = ether(1000000000); //1 B * 10^18
      const tokensMintedPerDay = ether(30000); // 30000 * 10^18
      assert((await token.name()) === 'Moonwhale');
      assert((await token.decimals()).toString() === '18');
      assert((await token.gameficationWallet()) === gameficationWallet);
      assert((await token.creationTime()).toNumber() === creationTime);
      (await token.TOKENS_MINTED_PER_DAY()).should.be.bignumber.equal(tokensMintedPerDay);
      assert((await token.symbol()) === 'XMM');
      (await token.INITIAL_SUPPLY()).should.be.bignumber.equal(INITIAL_SUPPLY);
      const initialBalance = await token.balanceOf(owner);
      initialBalance.should.be.bignumber.equal(INITIAL_SUPPLY);
      const isWhitelisted = await token.hasRole(owner, "whitelist");
      assert(isWhitelisted);
      assert((await token.tokensWithdrawn()).toString() === '0');
      assert((await token.owner()) === owner);
    });
  });

  describe('check num of tokens minted', async ()  => {
    let token;
    let tokensMintedPerDay;
    let gameficationWallet = accounts[1];
    beforeEach(async () => {
      token = await Token.new(gameficationWallet);
      tokensMintedPerDay = await token.TOKENS_MINTED_PER_DAY()
    })

    it('should mint 30000 tokens after day 1', async () => {
      const currentTime = latestTime();
      await increaseTimeTo(currentTime + duration.days(1));
      const numOfTokensMinted = await token.numTokensMinted();
      numOfTokensMinted.should.be.bignumber.equal(tokensMintedPerDay);
    })

    it('should mint 60000 tokens after day 2', async () => {
      const currentTime = latestTime();
      await increaseTimeTo(currentTime + duration.days(2));
      const numOfTokensMinted = await token.numTokensMinted();
      numOfTokensMinted.should.be.bignumber.equal(tokensMintedPerDay.mul(2));
    })

    it('should mint 60000 tokens after 2 days and 30 minutes', async () => {
      const currentTime = latestTime();
      await increaseTimeTo(currentTime + duration.days(2) + duration.minutes(30));
      const numOfTokensMinted = await token.numTokensMinted();
      numOfTokensMinted.should.be.bignumber.equal(tokensMintedPerDay.mul(2));
    })
  });
});
