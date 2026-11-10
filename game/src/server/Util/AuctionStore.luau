--!strict
-- Where the Auction House keeps its listings (Auctions.luau).
--
-- Live, two of Roblox's stores, shared by every server:
--   a DataStore holds each listing: the one true copy, changed only with UpdateAsync, so two servers can never both
--   sell the same thing or take the same bid;
--   a MemoryStore sorted map is the list every server reads to show what's for sale and to find auctions that have
--   ended. It's only a copy: if it misses a change, the DataStore still decides.
-- A Studio test of a published place uses stores of its own ("_Studio"), so tests never touch the real market.
-- A place that isn't published (a Rojo build) has neither, so the same calls work on plain tables there.

local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Auctions = require(ReplicatedStorage.Shared.Auctions)

type Listing = Auctions.Listing

export type Store = {
	Live: boolean,
	-- Saves a new listing. False if it couldn't (nothing was saved).
	Create: (listing: Listing) -> boolean,
	-- Changes a listing in one step: `transform` gets the saved one and returns the new one, or nil to change
	-- nothing. It can run more than once (if another server changed it meanwhile), so it mustn't do anything else.
	-- Returns whether it changed, and the new listing.
	Update: (id: string, transform: (old: Listing?) -> Listing?) -> (boolean, Listing?),
	Get: (id: string) -> Listing?,
	-- The browse list
	Index: (listing: Listing) -> (),
	Unindex: (id: string) -> (),
	All: () -> { Listing }?, -- nil if it couldn't be read
}

local TRIES = 3
local PAGE = 200
local MOST_PAGES = 15
local KEEP_AFTER_END = 3 * 86400 -- seconds a listing stays in the browse list after it ends, until it's settled
local LONGEST = 3888000 -- MemoryStore's limit, 45 days

local AuctionStore = {}

-- Calls `f` up to TRIES times, waiting a little longer each time
local function retry(what: string, f: () -> any): (boolean, any)
	local lastError: any = nil
	for attempt = 1, TRIES do
		local ok, result = pcall(f)
		if ok then
			return true, result
		end
		lastError = result
		task.wait(0.5 * attempt)
	end
	warn(`[AuctionStore] {what} failed: {lastError}`)
	return false, nil
end

local function live(): Store
	local suffix = if RunService:IsStudio() then "_Studio" else ""
	local records = DataStoreService:GetDataStore("Auctions_v1" .. suffix)
	local index = MemoryStoreService:GetSortedMap("AuctionIndex_v1" .. suffix)

	local function key(id: string): string
		return "L_" .. id
	end

	local store = {} :: Store
	store.Live = true

	function store.Create(listing)
		local made = false
		local ok = retry(`create {listing.Id}`, function()
			made = false
			records:UpdateAsync(key(listing.Id), function(old): any
				if old ~= nil then
					return nil
				end
				made = true
				return listing
			end)
			return nil
		end)
		return ok and made
	end

	function store.Update(id, transform)
		local changed: Listing? = nil
		local ok = retry(`update {id}`, function()
			changed = nil
			records:UpdateAsync(key(id), function(old): any
				local new = transform(old)
				changed = new
				return new
			end)
			return nil
		end)
		return ok and changed ~= nil, changed
	end

	function store.Get(id)
		local ok, value = retry(`get {id}`, function()
			return records:GetAsync(key(id))
		end)
		return if ok and type(value) == "table" then value :: Listing else nil
	end

	function store.Index(listing)
		local ttl = math.clamp(listing.Ends - os.time() + KEEP_AFTER_END, 60, LONGEST)
		retry(`index {listing.Id}`, function()
			index:SetAsync(listing.Id, listing, ttl)
			return nil
		end)
	end

	function store.Unindex(id)
		retry(`unindex {id}`, function()
			index:RemoveAsync(id)
			return nil
		end)
	end

	function store.All()
		local all: { Listing } = {}
		local after: string? = nil
		for _ = 1, MOST_PAGES do
			local ok, page = retry("read the list", function()
				return index:GetRangeAsync(Enum.SortDirection.Ascending, PAGE, after)
			end)
			if not ok or not page then
				return nil
			end
			for _, entry in page :: { any } do
				if type(entry.value) == "table" then
					table.insert(all, entry.value)
				end
				after = entry.key
			end
			if #(page :: { any }) < PAGE then
				break
			end
		end
		return all
	end

	return store
end

-- Plain tables, for a place that isn't published
local function inMemory(): Store
	local records: { [string]: Listing } = {}
	local index: { [string]: Listing } = {}
	local store = {} :: Store
	store.Live = false

	function store.Create(listing)
		if records[listing.Id] then
			return false
		end
		records[listing.Id] = table.clone(listing)
		return true
	end

	function store.Update(id, transform)
		local old = records[id]
		local new = transform(if old then table.clone(old) else nil)
		if new == nil then
			return false, nil
		end
		records[id] = table.clone(new)
		return true, new
	end

	function store.Get(id)
		local found = records[id]
		return if found then table.clone(found) else nil
	end

	function store.Index(listing)
		index[listing.Id] = table.clone(listing)
	end

	function store.Unindex(id)
		index[id] = nil
	end

	function store.All()
		local ids = {}
		for id in index do
			table.insert(ids, id)
		end
		table.sort(ids)
		local all = {}
		for _, id in ids do
			table.insert(all, table.clone(index[id]))
		end
		return all
	end

	return store
end

function AuctionStore.new(): Store
	if game.GameId == 0 then
		return inMemory()
	end
	return live()
end

return AuctionStore
