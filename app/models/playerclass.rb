class Playerclass
  PLAYERCLASSES = {
    1 => {
      images: [
        { url: "home/classes/blue_scout.webp", alt: "Blue scout icon" },
        { url: "home/classes/red_scout.webp", alt: "Red scout icon" },
      ],
      name: "Scout",
      speed: "450",
      armour: "25 Green",
      weapons: ["Nailgun", "Shotgun", nil, "Axe"],
      grenades: ["Flash / Caltrops", "Concussion"],
      specials: ["Dash", "Scanner"],
      attributes: ["Can uncover enemy spies", "Can disarm detpacks"],
    },
    2 => {
      images: [
        { url: "home/classes/blue_sniper.webp", alt: "Blue sniper icon" },
        { url: "home/classes/red_sniper.webp", alt: "Red sniper icon" },
      ],
      name: "Sniper",
      speed: "300",
      armour: "40 Green",
      weapons: ["Sniper Rifle", "Assault Rifle", "Nailgun", "Axe"],
      grenades: ["Frag", "Flare"],
      specials: ["Zoom"],
      attributes: [],
    },
    3 => {
      images: [
        { url: "home/classes/blue_soldier.webp", alt: "Blue soldier icon" },
        { url: "home/classes/red_soldier.webp", alt: "Red soldier icon" },
      ],
      name: "Soldier",
      speed: "240",
      armour: "200 Red",
      weapons: ["Rocket Launcher", "Super Shotgun", "Shotgun", "Axe"],
      grenades: ["Frag", "Shock / Nail"],
      specials: [],
      attributes: [],
    },
    4 => {
      images: [
        { url: "home/classes/blue_demoman.webp", alt: "Blue demoman icon" },
        { url: "home/classes/red_demoman.webp", alt: "Red demoman icon" },
      ],
      name: "Demolitions Man",
      speed: "280",
      armour: "110 Yellow",
      weapons: ["Pipe Launcher", "Grenade Launcher", "Shotgun", "Axe"],
      grenades: ["Frag", "MIRV"],
      specials: ["Detonate pipebombs", "Set detpack"],
      attributes: [],
    },
    5 => {
      images: [
        { url: "home/classes/blue_medic.webp", alt: "Blue medic icon" },
        { url: "home/classes/red_medic.webp", alt: "Red medic icon" },
      ],
      name: "Medic",
      speed: "320",
      armour: "90 Yellow",
      weapons: ["Super Nailgun", "Super Shotgun", "Shotgun", "Medi/Bio Weapon"],
      grenades: ["Frag", "Blast / Concussion"],
      specials: ["Healing Aura"],
      attributes: ["Immune to concussion"],
    },
    6 => {
      images: [
        { url: "home/classes/blue_hwguy.webp", alt: "Blue heavy icon" },
        { url: "home/classes/red_hwguy.webp", alt: "Red heavy icon" },
      ],
      name: "Heavy Weapons Guy",
      speed: "230",
      armour: "300 Red",
      weapons: ["Assault Cannon", "Super Shotgun", "Shotgun", "Axe"],
      grenades: ["Frag", "MIRV"],
      specials: ["Cannon Lock"],
      attributes: ["Reduced knockback when taking damage"],
    },
    7 => {
      images: [
        { url: "home/classes/blue_pyro.webp", alt: "Blue pyro icon" },
        { url: "home/classes/red_pyro.webp", alt: "Red pyro icon" },
      ],
      name: "Pyro",
      speed: "300",
      armour: "150 Yellow",
      weapons: ["Flamethrower", "Incendiary Cannon", "Shotgun", "Axe"],
      grenades: ["Frag", "Napalm"],
      specials: ["Airblast"],
      attributes: ["Is resistant to fire"],
    },
    8 => {
      images: [
        { url: "home/classes/blue_spy.webp", alt: "Blue spy icon" },
        { url: "home/classes/red_spy.webp", alt: "Red spy icon" },
      ],
      name: "Spy",
      speed: "300",
      armour: "90 Yellow",
      weapons: ["Nailgun", "Super Shotgun", "Tranq Gun", "Knife"],
      grenades: ["Frag", "Hallucinogenic Gas"],
      specials: ["Feign", "Disguise"],
      attributes: ["Can uncover enemy spies"],
    },
    9 => {
      images: [
        { url: "home/classes/blue_engineer.webp", alt: "Blue engineer icon" },
        { url: "home/classes/red_engineer.webp", alt: "Red engineer icon" },
      ],
      name: "Engineer",
      speed: "300",
      armour: "30 Yellow",
      weapons: ["Railgun", "Super Shotgun", "Shotgun", "Spanner"],
      grenades: ["Frag", "EMP"],
      specials: ["Dispenser", "Sentry Gun"],
      attributes: ["Can dismantle enemy Buildings"],
    },
  }

  def initialize(number)
    @playerclass = PLAYERCLASS[n]
  end

  def emoji(team)
    Rails.config.playerclass_emojis[team]
  end
end
