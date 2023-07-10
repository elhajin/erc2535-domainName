# 🔷 Domain Names Facet 🔷:

## _<span style = "color: yellow"> functionality : </span>_

1. **buy domainName** : this function allow any user to buy a domain name **_.mnt_** .

   1. the price of the name is depends on it's lenght and there are three prices 👍
      - 1️⃣ if the length is less then 10 bytes : **price : 0.0005 eth**
      - 2️⃣ if the length is more then 10 and less then 20 : **price : 0.001 eth**
      - 3️⃣ if the length is more then 20 and less then 32 (and it should) : **price : 0.009 eth**
   2. requirments :

      1. the name that user wanna buy should be available which means no one did buy it befor this user
      2. the domain Name + `.mnt` should be less than _32bytes_.
      3. the max years the user can choose is _10 years_ after that there is a **lifeTime** choice, which have constant price .

   3. the prices is for one year ownership of the name ,
   4. if the buyer wanna buy the name for more then one year, the price calculated with this formula :
      `price = priceForYear + (price - (years * 7 * priceForYear /100)) * years `

      > the user get better discount for more years he buy , the discount is the sub of original price and (years multiplied by 7)% of the price , for each Additional year .

2. **Sell domainName** : this function allow any user to sell any domain that he have. with a fix price that he set or by putting it in **_auction_**
   1. **_fixed Price domain_** : the user can put the domain that he own to sell in a fixed price that he specify, the first address how offer this price of higher then this price, will get the domain name.
   2. **_auction_**: the user can put any domain name that he own in the **_auction_** with some inputs that define the requirment for a Successful trade. - the user should set the lower price willing to get. - the user should set the duration for **_auction_** to be closed
      after the duration is passed . the address who offer the higher price will get the name if the price is up then the lower price the user set.
      the owner of the name also have the ability to close the auction in any price if he want. but not allowed to get the name if there is a higher price then the price he set as lower price is already offered.
