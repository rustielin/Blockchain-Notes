Bitcoin Mechanics and Optimizations 
===================================

After abstracting away Bitcoin features to focus on fundamental
principles and design, it’s time to dive into how Bitcoin works on a
technical level. In this note, we will cover topics such as advanced
Bitcoin mechanics, scripting, and network optimizations techniques.
Through these topics, we intend on demonstrating that Bitcoin’s design
philosophy is as simple, robust, and conservative as possible.

Double Spend — Example 
======================

To gain further intuition on Bitcoin consensus, let’s understand once
more the problem it solves: double spending. Previously, we defined a
“double spend" as a circumstance in which a party successfully spends
the same funds more than once. In real life, it’s as if you used a
single dollar bill in two separate purchases. Physically, it’s
impossible to double spend, but the virtual world creates issues. For
example, if Alice wants to purchase something from Bob for 1.00 BTC, she
can double spend by creating two transactions: send 1.00 BTC to Bob in
one transaction, and 1.00 BTC to herself in another. The double spend is
successful if the transaction to herself is the one accepted by the
network, which will allow her to keep the money and fool Bob. Double
spends are possible when a party gains more than 50% of the network’s
hash power. Under the hood, there is a fairly involved process that
results in the double spend.

Double Spend — Confirmations 
============================

A transaction’s **confirmations** are defined as the blocks built off of
the block containing the transaction. All transactions in the block at
the tip of the blockchain have 0 confirmations, as there are no newer
blocks. A transaction’s confirmations will be one less than the block
depth: the most recent block is at depth 1 and has 0 confirmations, and
every next block will increase both the depth and confirmations by one.

![image](confirmations)

Why do confirmations matter? Suppose Bob does not wait for any
confirmations on Alice’s transaction. He checks that the transaction
from Alice is valid and *immediately* sends Alice the product he is
selling, such as if Alice were buying coffee at a cafe where waiting up
to an hour for confirmations would inconvenience everyone involved.
Since there are no confirmations on Bob’s transaction, Bob is vulnerable
to a **race attack**. Alice can send a competing transaction to herself
at the same time she sends Bob the legitimate transaction, as previously
mentioned. Alice can then broadcast the transaction to the entire
network. The false, conflicting transaction Alice sends is propagated
much faster than the single transaction she sends to Bob, so there is a
high likelihood that one of the Alice’s conflicting transactions will be
mined into a block and accepted by the network as genuine. Alice can
also increase the block fee for the transaction to provide more
incentive for miners to include the illegitimate transaction into their
blocks. In this case, merchant Bob’s waiting for 0 transactions makes
him vulnerable to anyone that wants to steal goods.

On the other hand, in the case that Bob waits for more than 1
confirmation ($z$ confirmations), Alice must go through a much more
involved process to double spend. Say Alice sends Bob a transaction, and
Bob waits $z$ confirmations before he sends the goods to Alice. In order
to double spend on Bob, Alice must mine on her own private chain, one
that does not have the transaction that sent bitcoin from Alice to Bob;
Alice can send the same transaction to herself instead. She builds up an
illegitimate transaction history such that she sends money to herself
rather than to Bob. After mining $z$ blocks, and making sure that her
chain is longer than any other chain, Alice can broadcast her chain
(preferably after she receives the goods from Bob). The network will
adopt Alice’s chain over the previous chain because it is longer in
length. In fact, it is proven that if Alice has greater than 50% of the
total hash power, then she can always generate a longer, illegitimate
chain.

![image](z_confirmation)

Double Spend — Security 
=======================

Let’s model our assertions about double spending and hash power with
mathematics:

Suppose Bob waits for $z$ confirmations before sending his goods over to
Alice. Alice has $h_A$ hash power, and the honest network has $h_H$ hash
power. The total network hash power is then $h_A + h_H$. The
probability, $p$, of the honest network finding the next block is simply
the proportion of hash power the honest network controls:
$$p = \frac{h_H}{h_A + h_H}$$

The probability, $q$, of Alice finding the next block is the complement
of $p$. We calculate it as follows: $$\begin{split}
           q &= 1-p \\
           &= 1 - \frac{h_H}{h_A + h_H} \\
           &= \frac{h_A}{h_A + h_H}
       \end{split}$$

Consider the scenario in which the honest network mines $z$ blocks on
top of Alice’s transaction to him. Bob sees that there are $z$
confirmations, and then he sends the goods over to Alice. In the
meantime, Alice has been hard at work mining on her own chain ever since
sending her transaction over, in hopes of double spending on Bob. If
$\lambda$ equals the expected number of blocks mined by Alice in the
time that $z$ blocks are mined by the honest network, then we see that
$\lambda$ depends on the ratio of the mining power of each entity (Alice
vs the honest network):

$$\lambda = z(\frac{q}{p})$$

(: if $p = q = 0.5$, then $\lambda = z$, meaning that we expect Alice to
mine mine the exact same number of blocks as the honest network. This
makes sense, that two entities with equal power would produce an equal
number of valid blocks.)

If we model this as a **Poisson distribution**, because we have discrete
events each corresponding to a probability, we can show that the
probability that Alice generates $k$ blocks is:

$$p_A(k) = \frac{\lambda^k e^{-\lambda}}{k!}$$

Now the question is: What is the probability Alice can mine enough
blocks in secret to successfully broadcast her chain with the double
spend? In other words, what is the probability that Alice can produce a
longer chain than the honest network?

To solve this, first consider the related problem of Alice trying to
catch up to a chain that is $j$ blocks ahead of Alice’s own chain. The
corresponding question is: What is the probability that Alice will ever
catch up given an unlimited number of trials? It is also important to
consider that the honest network is continuously mining their blocks on
their chain, while Alice works maliciously on the side. This problem is
actually an instance of the **Gambler’s Ruin** problem, which in this
case means that if Alice has more than 50% hash power, she can always
generate a longer chain, given infinite time. The following is the
probability of Alice catching up if she is $j$ blocks behind:

$$p_c(j) = \begin{cases} 
      1 & q \geq p \text{ OR } j < 0 \\
      \big(\frac{q}{p}\big)^j & q < p
   \end{cases}$$

In other words, Alice can succeed in eventually producing a longer chain
if she either has at least as much hash power than the rest of the
network or if she is already ahead of the rest of the network. On the
other hand, if she has less hash power than the rest of the network, she
may still be able to catch up based on the ratio of her own hash power
fraction to the rest of the network. The more blocks she is behind, the
smaller her chance of producing the longest chain and “winning."

Combining these two probabilities, we can compute the probability that
Alice can catch up after $z$ blocks mined on the honest chain. Consider
the case when Alice mines $k$ blocks. This means that the honest chain
is $z-k$ blocks ahead of Alice. We sum over all possible values of $k$:

$$\begin{split}
           &\Sigma_{k=0}^\infty p_A(k) \cdot p_C(z-k) \\
           = &\Sigma_{k=0}^\infty \frac{\lambda^k e^{-\lambda}}{k!} \cdot  \left\{
    \begin{array}{ll}
      1  & k > z \\ 
      \big(\frac{q}{p}\big)^{z-k} & k \leq z \\
    \end{array}
  \right.
       \end{split}$$

![image](doublespend_plots)

The above shows Alice’s probability of catching up to the honest chain
in arbitrary $x$ number of blocks. If Alice has 50% hash power or more,
then she can catch up with 100% probability. Probability of catching up
to the honest chain decreases as Alice’s probability $q$ of getting the
next block decreases.

To avoid **infinite tail discrete summation**, we can look at the
inverse probability that Alice *cannot* catch up to the chain that is
$j$ blocks ahead:

$$\begin{split}
           & 1 - \Sigma_{k=0}^\infty \frac{\lambda^k e^{-\lambda}}{k!} \cdot  \left\{
    \begin{array}{ll}
      1  & k > z \\ 
      \big(\frac{q}{p}\big)^{z-k} & k \leq z \\
    \end{array}
  \right. \\
  &= 1 -\Sigma_{k=0}^\infty \frac{\lambda^k e^{-\lambda}}{k!} \cdot \Bigg(1- \big(\frac{q}{p}\big)^{z-k}\Bigg)
        \end{split}$$

The number of confirmations Bob should wait before sending Alice the
goods depends on how much hash power Bob assumes Alice to control. After
6 confirmations, the likelihood of a double spend attack drops to zero
assuming any malicious party controls 10% or less of the network hash
power.

Double Spend — Bribing Miners 
=============================

We have shown that if Alice controls more than 50% of the total network
hash power, she will always be able to double spend. Looking back at our
calculations, whenever Alice is some $j$ blocks behind the honest
network’s chain, she will *always* (in expectation) be able to catch up
and out-produce the honest miners. Hence, the probability that Alice can
successfully double spend with greater than 50% network hash power is 1.

In reality, it is extremely costly and implausible for Alice to own so
much network hash power, especially given the Bitcoin network’s current
vastness. While Alice might not physically control mining hardware for a
double spend attack, she can bribe other willing miners or even entire
mining pools to mine on her chain. In the long run, Alice and her miners
will profit after managing to overcome the extremely high initial cost.

Double Spend — “Goldfinger" Attack 
==================================

**“Your scientists were so preoccupied with whether or not they could,
they didn’t stop to think if they should." — Ian Malcolm, *Jurassic
Park***

Is double spending a good idea, even with the proper resources? If Alice
does in fact succeed, confidence in Bitcoin’s value would plummet after
the rest of the network detects the security breach. Alice’s bitcoins
would also tank in value, assuming Alice is staked in Bitcoin when she
performs the attack.

However, if Alice wants to use this price drop to her own advantage, she
can instead **short** Bitcoin in order to profit after her double spend.
Alice can short the exchange rate and use that as collateral to buy,
rent, or bribe miners, cashing out on the short.

Consider Alice as a hostile government, adversarial altcoin, or large
financial institution with a large amount of **capital**. Alice would
then be able to acquire enough mining equipment or bribe enough miners
or pools to achieve greater than 50% hash power. Alice can then perform
a so-called **Goldfinger attack**, with the objective of destroying the
target cryptocurrency with a double spend or spamming the network with
empty blocks.

(Note: The Goldfinger attack references the famous villain Auric
Goldfinger from the third James Bond movie, who poisons the US gold
supply in Ft. Knox to reduce the value of that US gold and to increase
the value of his own gold holdings.)

Account vs Transaction Based Ledgers 
====================================

Consider the notion of **account-based ledgers**. Cryptocurrencies such
as Ethereum maintain account-based ledgers. Each address in Ethereum
represents an account, and for a user to check how many tokens they
have, they simply add the inputs and subtract the outputs. The downside
to this method is that the system must track every single transaction
that has ever affected that one account, a potential peformance issue
when scaling to thousands of users. A possible fix? ‘Pruning’ away old
transaction history so that the user does not have to deal with old
transaction data. (Currently error-prone due to additional required
block maintenance.)

Bitcoin is a **transaction-based ledger** (also known as triple-entry
accounting). Users are always spending from previous outputs. As we
mentioned in Note 2, UTXOs (unspent transaction outputs) can only be
spent once. When someone wants to spend a portion of a UTXO, they send
part to the receiving party and the remaining to a “change address"
controlled by themselves, for later use. Restricting UTXO usage and
introducing the concept of change addresses produces an efficient
verification system: to determine how many tokens a user has, sum their
valid unspent UTXOs. Bitcoin also supports joint payments, so that a
transaction can have multiple inputs – for example if Alice and Bob both
want to pitch in to spend a total of 1.00 BTC. In practice, this feature
is rarely used but is supported nonetheless.

Contents of a Transaction 
=========================

The contents of a Bitcoin transaction fall into three categories:
metadata, inputs, and outputs.

![image](transaction_contents)

As seen above, a transaction follows **JSON** structure. Metadata
contains information such as the hash of the current transaction (aka
the transaction ID), the **version number** (currently 1), the number of
inputs and outputs, **lock time**, and **data size**.

Inputs to the transaction include a hash of a previous unspent
transaction and an index, which specify the output of the previous
transaction from which the user is spending. Transaction outputs are
ordered, so an index is required to identify specific outputs in a
transaction. Inputs also need a cryptographic signature as a proof of
ownership.

The outputs of a transaction include an output amount in BTC as well as
an **output script**. The output script is what enables the parties
associated with the transaction to claim their bitcoins later on, using
a system called the Pay-to-PubkeyHash, which we will discuss later.
Shallowly, the script says, “Whoever owns the private key to this public
key can redeem these bitcoins."

Bitcoin Scripting 
=================

Previously we stated that transactions map input addresses to output
addresses. In practice, these “addresses" are scripts. By defining
inputs and outputs through scripting, we can allow for the future
extensibility of Bitcoin because scripting is such a low level feature
that could potentially support many other future operations if needed.
Recall that a signature proves the ownership of a public key, and that
the Bitcoin address is a hash of the public key.

$$Hash(PubKey)~==~Address~==~"PubKeyHash"$$

Inputs and outputs are scripts that these addressses, and sending money
through transactions involves previously unspent transaction outputs.

So outputs in a transaction must be constructed in a way that tells the
network:

“This amount can be redeemed by a from the owner of address X.”

However, by the cryptographic property of preimage resistance, we know
that we cannot find a public key given an address. What the transaction
should really be saying is:

“This amount can be redeemed by the that hashes to address X, plus a
from the owner of that public key.”

Only the owner of the public key would be able to produce the valid
signature necessary to redeem the bitcoin from the output script.

To make input scripts compatible with output scripts, we concatenate the
input script to the output script, in that order. Input scripts are
called **scriptSigs** and output scripts are called **scriptPubKeys**.
This is because output scripts are specified by the senders of the
transaction. Outputs need to know a provider – a public key that hashes
to the associated address, and makes sure that the signature matches.

![image](output_script)

In terms of code execution, scripts are run line by line, top to bottom.
Notice in the diagram how the scriptSig is followed by the scriptPubKey
because of the concatenation convention, and also because outputs need
to know where the funds are coming from.

The Bitcoin scripting language, called **Script**, (the former is used
frequently too) is a simple stack based language. There exists no
support for loops, so the language is not Turing complete, but there
exists native support for cryptography, making the language very
specialized for its own needs. In fact, the entire signature
verification process can be written in code as one instruction.

Next, we present an example execution of the previously shown script.

![image](script_execution)\
The first two steps are $<$sig$>$ and $<$pubKey$>$, so we push those to
the stack in that order. Next, OP\_DUP simply duplicates the most recent
instruction, so by the end of executing the third instruction, there are
two $<$pubKey$>$’s. OP\_HASH160 hashes the topmost item, $<$pubKey$>$,
into $<$pubKeyHash$>$, as the name implies. $<$pubKeyHash?$>$ is the
address that redeemers of the output must hash their public key to.
Next, in the instruction OP\_EQUALVERIFY, the script checks to see if
$<$pubKey$>$ truly hashes to the address $<$pubKeyHash?$>$. The script
then cross checks this with the signature, $<$sig$>$, in OP\_CHECKSIG,
which returns true if the redeemer of this output is truly verified to
spend from this output. In a nutshell, the script returns either true or
false, depending on the legitimacy of the $<$sig$>$ and $<$pubKey$>$
that are passed in.

The output is saying: "This amount can be redeemed by

1.  the $<$pubKey$>$ that hashes to the address $<$pubKeyHash?$>$

2.  plus a $<$sig$>$ from the owner of that $<$pubKey$>$, which will
    make the output script evaluate to true."

Proof-of-Burn 
=============

One application of Bitcoin scripting is to implement something known as
a **proof-of-burn**, which allows a user to prove the existence of some
data in exchange for destroying bitcoin. There exists an instruction
named OP\_RETURN that throws an error when reached, stopping code
execution. By placing this instruction anywhere in an output script
before the script returns either true or false, we can effectively make
it so that no one can redeem that output. We have *burned* that coin.
Anything that exists after the OP\_RETURN will never be executed, but
this allows us to prove its existence cryptographically.

![image](burn_script)\
As seen in the sample script above, as long as we’re willing to burn
coin, we can prove the existence of anything at a particular point in
time. This would be a word you coined, a hash of a document, music, your
creative works, etc. If Alice stores a hash of a word she coined in the
blockchain via proof-of-burn, she could then show everyone that “Alice
coined word asdf at time 12345." Any data stored in this way in the
blockchain is valid because blocks are timestamped. This is especially
true when considering that the blockchain is provably immutable with
honest actors. There have also been instances of burning bitcoin to
bootstrap the value of other cryptocurrencies. To bootstrap an imaginary
SuperAwesomeCoin, Super Awesome Bob could require users to burn bitcoin
in order to get superAwesomeCoin.

Pay-to-PubKey-Hash vs Pay-to-Script-Hash 
========================================

The previous example of requiring a public key and a signature in order
to spend from a transaction output script is a use case of **P2PKH
(pay-to-pubkey-hash)**, in which the vendor says “send your coins to the
hash of this public key." This scheme represents the simplest and by far
the most common case of transaction.

However, for more complicated scripts, such as those which require
multiple signature verification, P2PKH no longer works. For instance, if
a merchant wants Alice to send coin payment to an output that allows the
merchant to spend using multiple signatures, how would Alice know how to
specify such a complicated script?

The solution is to use a **pay-to-script-hash (P2SH)**. To clarify,
consider following general cases:

-   P2PKH: “Send your coins to the hash of this ."

-   P2SH: “Send your coins to the hash of this . To redeem those coins,
    you must reveal the script that has the given hash and provide that
    will make the script evaluate to true."

One of the most important improvements to the Bitcoin protocol since its
inception, P2SH offloads the burden of complicated script writing to
recipients of a transaction. When a merchant wants to receive payments
from a customer, they do not want to burden the customer with writing a
complicated script that could potentially differ between merchants.
Instead, the merchant alone is responsible for writing a correct and
secure script for the transaction. Likewise, the optimal customer
experience is one in which the customer does not have to care about what
the script actually is. They should not have to know anything about the
company stores funds; customers should just have to create a
transaction, pay, and leave.

Merkle Trees 
============

Let’s take a deeper dive into the specifics of Merkle trees, which we
briefly touched upon in note 2. As review, merkle trees are inary trees
of hash pointers. Blobs of transaction data are hashed together, then
their hashes are hashed together, until one element remains—the Merkle
root. (Note: Merkle trees are always full. If there are gaps, duplicate
the last transaction to fill in the gaps.)

Outputs of cryptographic hash functions are unique by , making Merkle
trees efficient. The Merkle root serves as a summary of the Merkle tree
and as a mechanism to maintain history of included information. To prove
inclusion of data, one must provide root data and intermediate hashes.
After hashing everything together in order, one compares the final hash
to the merkle root. To fake this proof, one would need to find hash
preimages that hash to values in the merkle tree. As discussed earlier,
second preimage resistance makes faking proofs in merkle trees extremely
difficult and practically impossible.

![image](merkle_proof)

The figure above illustrates how one might prove the inclusion of a
substring $data$, the circled leaf node. Provided the circled $data$,
the proof proceeds as follows.

1.  Hash $data$ and call it $H_{data}$

2.  Hash $H_{data}$ with the next intermediate hash (height 2)

3.  Continue hashing until we reach height 0

4.  Hashing the two hashes at height 0 results in $H_{root}$

    1.  If $H_{root}$ is the same as the merkle root, then we have
        proven the existence of $data$ within the merkle tree

    2.  Else, the proof failed and the merkle tree does not contain
        $data$

Merkle Trees — Bitcoin Construction 
===================================

There are two main hash structures in Bitcoin. The blockchain is a hash
chain of blocks; the blocks are linked together and based off of each
other. They are tamper evident because changing one block changes its
hash, which mismatches with the next block’s hash of the previous block.
Merkle trees exist within blocks and are a way of storing transactions.
Changing data within a merkle tree changes its hashes, ultimately
bubbling up and changing the merkle root. Changing the merkle root in
turn changes the hash of the block it’s contained in, invalidating the
block.

Merkle Trees — Mining, In More Detail 
=====================================

Previously, we explained for simplicity that for every block, miners
hashed together the merkle root, the previous block’s hash, and a nonce
(varied value) to find a number that is below a certain target value.
There are actually two nonces: one in the block header as mentioned, and
one in the coinbase transaction, the transaction that is created by and
paid out to the miner. Changing the nonce in the coinbase transaction
changes the hash of the coinbase transaction, ultimately changing the
merkle root.

The reason why there are two nonces is to increase difficulty for the
miner. The block header nonce is 32 bits by itself. A modern ASIC such
as the Antminer S9 can hash at 14 TH/s. A simple calculation shows that
it takes just 0.00031 seconds to compute all the possible combinations
in the block header nonce.
$2^{32} / 14,000,000,000,000 = 0.00031 \text{~seconds}$. A miner with
the right hardware can exhaust all nonce combinations 3260 times per
second. Therefore, it is imperative to change the merkle root by
including the coinbase transaction nonce.

A common strategy is to increment the coinbase nonce, and then run
through all block header nonce combinations. A less efficient strategy
is to increment the block header nonce, and then run through all
combinations for the coinbase nonce. This is because changing the
coinbase nonce changes the merkle root, and the change must propagate up
the tree, wasting precious hash time. (Propagating up the merkle tree
takes $\theta(\log N)$ time, whereas calculating a hash takes
$\theta(1)$ time.) We want to minimize the time spent calculating new
merkle tree hashes, so change the coinbase transaction as little times
as possible.

SPV — Simplified Payment Verification 
=====================================

The current size of Bitcoin’s blockchain is 122.7 gigabytes and growing.
Miners, or “full nodes”, are required to save the entire blockchain, but
for the average user, such a requirement is not feasible if the aim is
mass adoption. Enter **SPV (Simplified Payment Verification) nodes**, or
“thin” clients. These nodes are designed to be lightweight, as their
name implies. They only store the pieces of data needed to verify
transactions that concern them, thus relieving the necessity to store
the entire blockchain. Nearly all nodes in the Bitcoin network are SPV
nodes because users are discouraged by the enormous download size. Those
that do run full nodes exchange large amounts of storage and a high
bandwidth for a shot at the block reward.

SPV nodes only keep the block headers of the blockchain. This is done by
querying different full nodes until the SPV node has the longest chain.
To validate an incoming transaction, an SPV node queries full nodes to
get the Merkle branch for that transaction. Then, the node hashes the
transaction together with intermediate hashes to obtain a Merkle root,
which is cross checked with the Merkle root in the corresponding block
header that the SPV node has locally. The only thing left to do after
this point is to wait for the transaction to have enough confirmations
(six) before delivering any goods.

SPV — Security and Cost Analysis 
================================

By definition, SPV nodes do not have a full transaction history, and do
not know the UTXO set. Therefore, SPV nodes do not have the same level
of security as full nodes. The reason is that SPV nodes cannot check if
every transaction included in a block is actually valid.

One major assumption SPV nodes make in exchange for their light weight
is that they assume incoming block headers are not a false chain. This
is a fair assumption to make because block headers include the
proof-of-work for each block, and it is very expensive for attackers to
create blocks. Over the long term, as long as the majority of the
network is honest, SPV nodes can safely assume that the longest chain is
honest because malicious behavior is not sustainable. Another assumption
is that there are other full nodes out in the network validating all
transactions. It is often inefficient for big merchants to query remote
full nodes to verify transactions. Instead, it makes sense to keep a
full blockchain to run fast local checks. Lastly, SPV nodes also assume
that miners ensure that the transactions they include in their bocks are
valid. If a miner were to include an invalid transaction, after they
find the proof-of-work for that block and propagate it, other full nodes
would reject their block because of the invalid transaction. Thus,
miners are well incentivized to make sure all transactions in their
blocks are valid.

The storage tradeoff for running an SPV is huge. Bock headers are only
around $\frac{1}{1000}$ the size of the full blockchain. This translates
to  123 MB vs. 123 GB. SPV nodes capitalize on obtaining data for
verifying transactions lazily, relying on data from full nodes rather
than keeping it locally. For most consumers and users of Bitcoin, SPV is
a decent tradeoff.

Flooding Algorithm 
==================

We mentioned that SPV nodes query full nodes to get data on block
headers. The mechanism through which an SPV node establishes connection
to full nodes is worthy of analysis too, especially since we have been
fairly hand-wavy when refering to the “Bitcoin network.”

The Bitcoin network ensures that all nodes are equal; there exist no
hierarchy of nodes or special nodes that have priority in any process:
consensus, transactions, etc. The network is thus fully decentralized.
The Bitcoin network is also defined by the property of random topology,
meaning that each node in the network pairs with random nodes. Messages
between nodes are generally taken as true, and the default behavior for
nodes is to accept whichever message they hear about first, but this is
not a strictly enforced rule in the network.

The process of joining the Bitcoin network is aided by the presence of
hard-coded **seed nodes** in the Bitcoin software. The algorithm is as
follows:

1.  Pick a seed node and ask for its peers

2.  Ask those peers for their peers, etc.

3.  Eventually, you pick a random set of nodes to pair with. These nodes
    become your peers.

In general, this type of message-sending schema is characterized by its
pairwise connections, and is called a **flooding algorithm** or **gossip
protocol**. The end goal is for the entire network to hear about a
transaction. Consider a simple example with our favorite characters
Alice and Bob:

1.  Alice wants to pay Bob, so Alice first constructs a transaction and
    tells all of her peers

2.  Her peers conduct checks on the transaction and if it passes, they
    relay the transaction to their peers

3.  Each peer conducts checks such as the following:

    -   Does the script for each previous output being redeemed return
        true?

    -   Have all redeemed outputs not been spent?

    -   Have I already seen this transaction? Do not relay it if so.

    -   Only accept and relay ”standard scripts“: based off a small
        whitelist of scripts.

4.  Eventually, the transaction makes it to Bob

Bitcoin Relay Network 
=====================

One problem Bitcoin is currently facing is **mining pool
centralization**. Miners are incentives to join large mining pools
because smaller mining pools generally experience higher orphaning rates
due to lesser hash power and network connectivity. Large pool on the
other hand have lower block orphan rates becauses of the effects of
**block propagation delays**.

One solution to this issue is the adoption of the **Bitcoin Relay
Network**, also known as the Fast Relay Network. The idea is to serve a
high speed “railroad for block data.” The design involves installing
nodes in China/Asia, Europe, North America, etc., prioritizing first
where the majority of miners are geographically located. Each of the
nodes would have a fast internet connection, and would be able to relay
data via compression and transmission via TCP to nearby miners. This
would rapidly improve bock propagation speed, and thus reduce the number
of orphaned blocks.

The problem with the Bitcoin Relay Network is that it relies on TCP as
its connectivity protocol. TCP is susceptible to data loss. A sender
might send $x$ number packets of data to a receiver, but not all $x$ may
arrive. In the case where not all packets arrive, the receiver is
notified, and can then ask to sender to resend the missing packets. This
causes a round trip delay for the time-sensitive data.

FIBRE 
=====

After realizing the problems with the Bitcoin Relay Network, developers
conceptualized **FIBRE (Fast Internet Bitcoin Relay Engine)**. Problems
with the Bitcoin Relay Network boiled down to its reliance on TCP, which
only implements error correction at the IP leve. It uses ARQ
(Automatically Repeat Request) to fix errors, which requires another
round trip from receiver to sender, back to the receiver. FIBRE fixes
this by opting for UDP (user Datagram Protocol), which allows for FEC
(Forward Error Correction). This means that if there are errors in
FIBRE, the receiver is ale to reconstruct the correct data block without
having to contact the sender to send it again. The sender simply
includes extra packets to account for potential packet loss or
corruption.

Key Terms 
=========

A collection of terms mentioned in the note which may or may not have
been described. Look to external sources for deeper understanding of any
non-crypto/blockchain terms.

1.  **Account-based ledger** — An account-based ledger associates

2.  **Bitcoin Relay Network** — Definition.

3.  **Block propagation delays** — Definition.

4.  **Confirmations** — Definition.

5.  **Fast Internet Bitcoin Relay Engine (FIBRE)** — Definition.

6.  **Flooding algorithm** — Definition.

7.  **Gambler’s Ruin** — Definition.

8.  **Goldfinger attack** — Definition.

9.  **Gossip protocol** — Definition.

10. **Mining pool centralization** — Definition.

11. **Pay to Public Key Hash (P2PKH)** — Definition.

12. **Pay to Public Script (P2PS)** — Definition.

13. **Proof-of-burn** — Definition.

14. **Race attack** — Definition.

15. **Seed node** — Definition.

16. **Simplified Payment Verification (SPV)** — Definition.

17. **Script** — Definition.

18. **ScriptPubKeys** — Definition.

19. **ScriptSigs** — Definition.

20. **Transaction-based ledger** — Definition.


