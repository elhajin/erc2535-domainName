# 🔷 Domain Names Facet 🔷:

### tabel of content :

- [functionlity](#functionality).
  - [buyDomainName](#1-buy-domainname-function--allow-any-user-to-buy-a-domain-name).
  - [sellDomainName](#2-sell-domainname--this-function-allow-any-user-to-sell-any-domain-that-he-have-with-a-fix-price-that-he-set-or-by-putting-it-in-auction).
  - [auction](#3-auction-sale).
  - [fixed price](#4-fixed-price-sale).

## _<span style = "color: yellow"> functionality : </span>_

### 1. **buy domainName function :** allow any user to buy a domain name .

1. **_requirment_** :

   1. the name that user wanna buy should be available which means no one did buy it befor this user,or the owner of this name is selling it in the [auction](#3-auction) or for [fixed price](#4-fixed-price-sale).
   2. the domain Name should be less then or equal _32bytes_.
   3. the max years the user can choose is _10 years_ if he choose more he will get **life time ownership**.

2. **_PRICE_**

- the price of the name is depends on it's lenght and there are three prices 👍

  - 1️⃣ if the length is less then 10 bytes : **price : 0.003 eth**
  - 2️⃣ if the length is more then 10 and less then 20 : **price : 0.006 eth**
  - 3️⃣ if the length is more then 20 and less then 32 (and it should) : **price : 0.01 eth**

    > `NOTICE:` If the user choose more then 10 years , he will get **_life time `ownership`_** which cost : **0.1 eth**

    > `NOTICE:` the prices is for one year ownership of the name .

  - if the buyer wanna buy the name for more then one year, the price calculated with this formula :
    `price = priceForYear + (price - (years * 7 * priceForYear /100)) * years `

    > the user get better discount for more years he buy , the discount is the sub of original price and (years multiplied by 7)% of the price , for each Additional year .

### 2. **Sell domainName** :

**_this function allow any user to sell any domain that he own. with a [fixed price](#4-fixed-price-sale) that he set or by putting it in [auction](#3-auction)_**

- **_requirements :_**

  1.  the caller of this function should be the owner of the provided domain.
  2.  the domain that the caller wanna sell, shoud be not already for sell.
  3.  the caller have to choose which type sale he wanna sell his domain [fixed price](#4-fixed-price-sale) or [auction](#3-auction).
  4.  the owner should specify the period (in seconds) that the domain will be available to sell.

- **more Info :**
  - if the domain is for sale, so in call function `ownerOf()` with a domain that for sale, will return the address(0). not the actaul owner.
  - the owner have the ability to revoke the domain name that he put on sale sale.
    > `NOTICE:` the owner can't revoke the domain if domain in live auction and an address already payed more then or equal lower price.
  -

### 3. Auction Sale:

### 4. Fixed Price Sale:
