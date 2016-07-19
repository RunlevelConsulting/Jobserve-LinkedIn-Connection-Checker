# BetCalc

## Overview

Betting is confusing, maths is confusing. This tool is designed to make the process of betting easier, quicker and hopefully more profitable by incorporating two popular betting strategies that take away the burden of performing calculations in what is often a fast-paced situation.

This is a browser-based tool that works on pretty much any website, it's unobtrusive and lightweight. The fact it can be quickly brought up on any webpage means you can quickly calculate odds across multiple websites.

Simply fill the odds you're working with into the text fields, enter how much you're willing to bet (optional) and select either 'Cover' or 'Dutch' to generate the stakes needed to place a Cover or Dutched bet.
<br><br>
Installation
-------------

 1. Press Ctrl+D to create a new bookmark _(I recommend adding the bookmark to your Bookmarks Bar for accessibility)_
 2. Right-click the new bookmark and hit **Edit** _(Chrome)_ or **Properties** _(Firefox / Internet Explorer)_
 3. Name the bookmark **BetCalc**.
 4. Paste the code below into the **URL** _(Chrome / Internet Explorer)_ or **Location** _(Firefox)_  field.
 5. Test the BetCalc appears by clicking the bookmark.
```bash 
javascript:function a(){script=document.createElement("script");script.src="https://rawgit.com/RunlevelConsulting/UsefulScripts/master/BetCalc/betcalc.js";document.getElementsByTagName('HEAD')[0].appendChild(script);}a();
```
<br>
Betting Methods
-------------

### Cover Bet

**Budget**: £100

| Selection     | Odds | Required Stake   | Return | Profit |
| :------- | :----: | :---: | :---: | :---: |
| Your Presumed Winner | 3.0 |  £65.76    | £197.28 | £97.28 |
| Possible Winner    | 4.6   |  £21.74   |£100.00| _Break Even_ |
| Possible Winner     | 8.0    |  £12.50  |£100.00| _Break Even_ |

A Cover bet is useful if you're fairly sure a single selection will win but want to cover yourself on other entries just in case.

This method tends to produce higher profits and reduced losses but has a lower hit rate than a Dutched bet because if you didn't select the correct runner, you'll only receive your initial stake back.

### Dutch Bet

**Budget**: £100

| Selection     | Odds | Required Stake   | Return | Profit |
| :------- | :----: | :---: | :---: | :---: |
| Possible Winner | 3.0 |  £49.33   | £147.99 | £47.99 |
| Possible Winner    | 4.6   |  £32.17   |£147.98| £47.98 |
| Possible Winner     | 8.0    |  £18.50  |£148.00| £48.00 |

Dutching allows you to spread potential profits across multiple runners and receive an equal profit, regardless of who goes on to win.

In this example, if any runner goes on to win, you'll make a profit of about £48. This method usually means you win money more often, but because it requires you to back multiple runners, profits are lower than Cover bets.
<br><br>
Other Information
-------------
- Assuming you've completed the steps above correctly, this should work on all modern browsers.
- Feel free to input fractional odds, they work too.
- The BetCalc is draggable! Click, hold and drag the bold **BetCalc** title on the applet.
- Close the BetCalc tool by clicking the bookmark again.
- Round your bets to the nearest £5 or £10! Bookies can spot these kinds of bets a mile away and will restrict/close your account if you bet very specific amounts.
- **Bet responsibly.**

