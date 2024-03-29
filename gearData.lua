local gearData = {}

gearData.selectedStats = {
    [1] = "Character",
    [2] = "Name",
    [3] = "AC",
    [4] = "HP",
    [5] = "Mana",
    [6] = "ItemSlot",
    [7] = "ID",
    [8] = "Class",
    [9] = "ItemDelay",
    [10] = "Damage"
    
}

gearData.slots = {
    [0] = "charm",
    [1] = "leftear",
    [2] = "head",
    [3] = "face",
    [4] = "rightear",
    [5] = "neck",
    [6] = "shoulder",
    [7] = "arms",
    [8] = "back",
    [9] = "leftwrist",
    [10] = "rightwrist",
    [11] = "ranged",
    [12] = "hands",
    [13] = "mainhand",
    [14] = "offhand",
    [15] = "leftfinger",
    [16] = "rightfinger",
    [17] = "chest",
    [18] = "legs",
    [19] = "feet",
    [20] = "waist",
    [21] = "powersource",
    [22] = "ammo"
}

gearData.itemTypesToDisplay = {
    Character = true,
    ID = false,
    Name = true,
    Lore = false,
    NoDrop = false,
    NoRent = false,
    Magic = false,
    Value = false,
    Size = false,
    Weight = false,
    Stack = false,
    Type = false,
    Charges = false,
    LDoNTheme = false,
    DMGBonusType = false,
    BuyPrice = false,
    Haste = true,
    Endurance = true,
    Attack = false,
    HPRegen = false,
    ManaRegen = false,
    DamShield = false,
    WeightReduction = false,
    SizeCapacity = false,
    Combinable = false,
    Skill = false,
    Avoidance = false,
    SpellShield = false,
    StrikeThrough = false,
    StunResist = false,
    Shielding = false,
    FocusID = false,
    ProcRate = false,
    Quality = false,
    LDoNCost = false,
    AugRestrictions = false,
    AugType = false,
    AugSlot1 = false,
    AugSlot2 = false,
    AugSlot3 = false,
    AugSlot4 = false,
    AugSlot5 = false,
    AugSlot6 = false,
    Damage = true,
    Range = false,
    DMGBonus = false,
    RecommendedLevel = false,
    Delay = false,
    Light = false,
    Level = false,
    BaneDMG = false,
    SkillModValue = false,
    InstrumentType = false,
    InstrumentMod = false,
    RequiredLevel = false,
    BaneDMGType = false,
    AC = true,
    HP = true,
    Mana = false,
    STR = false,
    STA = false,
    AGI = false,
    DEX = false,
    CHA = false,
    INT = false,
    WIS = false,
    svCold = false,
    svFire = false,
    svMagic = false,
    svDisease = false,
    svPoison = false,
    Summoned = false,
    Artifact = false,
    PendingLore = false,
    LoreText = false,
    Items = false,
    Item = false,
    Container = false,
    Stackable = false,
    InvSlot = false,
    SellPrice = false,
    WornSlot = false,
    WornSlots = false,
    CastTime = false,
    Spell = false,
    EffectType = false,
    Tribute = false,
    Attuneable = false,
    Timer = false,
    ItemDelay = false,
    TimerReady = false,
    StackSize = false,
    Stacks = false,
    StackCount = false,
    FreeStack = false,
    MerchQuantity = false,
    Classes = false,
    Class = false,
    Races = false,
    Race = false,
    Deities = false,
    Deity = false,
    Evolving = false,
    svCorruption = false,
    Power = false,
    MaxPower = false,
    Purity = false,
    Accuracy = false,
    CombatEffects = false,
    DoTShielding = false,
    HeroicSTR = false,
    HeroicINT = false,
    HeroicWIS = false,
    HeroicAGI = false,
    HeroicDEX = false,
    HeroicSTA = false,
    HeroicCHA = false,
    HeroicSvMagic = false,
    HeroicSvFire = false,
    HeroicSvCold = false,
    HeroicSvDisease = false,
    HeroicSvPoison = false,
    HeroicSvCorruption = false,
    EnduranceRegen = false,
    HealAmount = false,
    Clairvoyance = false,
    DamageShieldMitigation = false,
    SpellDamage = false,
    Augs = false,
    Tradeskills = false,
    ItemSlot = false,
    ItemSlot2 = false,
    PctPower = false,
    Prestige = false,
    FirstFreeSlot = false,
    SlotsUsedByItem = false,
    Heirloom = false,
    Collectible = false,
    NoDestroy = false,
    Quest = false,
    Expendable = false,
    ItemLink = false,
    Icon = false,
    SkillModMax = false,
    OrnamentationIcon = false,
    ContentSize = false,
    Open = false,
    NoTrade = false,
    AugSlot = false,
    Clicky = false,
    Proc = false,
    Worn = false,
    Focus = false,
    Scroll = false,
    Focus2 = false,
    Mount = false,
    Illusion = false,
    Familiar = false,
    Blessing = false,
    CanUse = false,
    LoreEquipped = false,
    Luck = false,
    MinLuck = false,
    MaxLuck = false,
    IDFile = false,
    IDFile2 = false
}

return gearData