import {
  EIP712DomainChanged as EIP712DomainChangedEvent,
  ListingCancelled as ListingCancelledEvent,
  NFTListed as NFTListedEvent,
  NFTPurchased as NFTPurchasedEvent
} from "../generated/NFTMarket/NFTMarket"
import {
  EIP712DomainChanged,
  ListingCancelled,
  NFTListed,
  NFTPurchased
} from "../generated/schema"

export function handleEIP712DomainChanged(
  event: EIP712DomainChangedEvent
): void {
  let entity = new EIP712DomainChanged(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleListingCancelled(event: ListingCancelledEvent): void {
  let entity = new ListingCancelled(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.listingId = event.params.listingId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleNFTListed(event: NFTListedEvent): void {
  let entity = new NFTListed(
    event.params.seller.concatI32(event.params.listingId.toI32())
  )
  entity.listingId = event.params.listingId
  entity.seller = event.params.seller
  entity.nftContract = event.params.nftContract
  entity.tokenId = event.params.tokenId
  entity.price = event.params.price

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleNFTPurchased(event: NFTPurchasedEvent): void {
  let entity = new NFTPurchased(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.listingId = event.params.listingId
  entity.buyer = event.params.buyer
  entity.seller = event.params.seller
  entity.price = event.params.price

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  let sellerID = event.params.seller.concatI32(event.params.listingId.toI32())
  let listing = NFTListed.load(sellerID)
  if (!listing) {
    return
  }

  entity.list = listing.id

  entity.save()
}
