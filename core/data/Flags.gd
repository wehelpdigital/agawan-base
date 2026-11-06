class_name Flags
extends RefCounted
## Every flag you can carry. Countries follow the UN's list, leaving out flags with sacred writing on them, which
## don't belong on a cartoon. Every country is free, so anyone can fly their own; the fun flags cost coins.
##
## A flag is drawn from SVG on a 60 x 40 sheet: `h` horizontal stripes, `v` vertical stripes, then `art`:
##   ["disc", x, y, r, colour]        ["star", x, y, r, colour]         ["rect", x, y, w, h, colour]
##   ["tri", x1, y1, x2, y2, x3, y3, colour]   ["cross", x, y, thick, colour]   ["saltire", thick, colour]
##   ["moon", x, y, r, colour]        ["ring", n, x, y, far, r, colour]   ["path", d, colour]

const ALL: Array[Dictionary] = [
	{"id": "", "name": "No Flag", "rarity": "free"},
	# Asia
	{"id": "ph", "name": "Philippines", "rarity": "free", "region": "asia", "h": ["0038a8", "ce1126"], "art": [["tri", 0, 0, 30, 20, 0, 40, "ffffff"], ["disc", 9, 20, 4, "fcd116"], ["star", 3.5, 6, 2, "fcd116"], ["star", 3.5, 34, 2, "fcd116"], ["star", 22, 20, 2, "fcd116"]]},
	{"id": "jp", "name": "Japan", "rarity": "free", "region": "asia", "h": ["ffffff"], "art": [["disc", 30, 20, 12, "bc002d"]]},
	{"id": "kr", "name": "South Korea", "rarity": "free", "region": "asia", "h": ["ffffff"], "art": [["disc", 30, 20, 10, "cd2e3a"], ["path", "M20 20 A10 10 0 0 0 40 20 A5 5 0 0 0 30 20 A5 5 0 0 1 20 20 Z", "0047a0"], ["path", "M8 9 l6 -4 l1 2 l-6 4 Z M46 7 l6 4 l-1 2 l-6 -4 Z M8 31 l6 4 l1 -2 l-6 -4 Z M46 33 l6 -4 l-1 -2 l-6 4 Z", "0a1426"]]},
	{"id": "cn", "name": "China", "rarity": "free", "region": "asia", "h": ["de2910"], "art": [["star", 11, 11, 7, "ffde00"], ["star", 21, 4, 2.2, "ffde00"], ["star", 25, 9, 2.2, "ffde00"], ["star", 25, 15, 2.2, "ffde00"], ["star", 21, 20, 2.2, "ffde00"]]},
	{"id": "in", "name": "India", "rarity": "free", "region": "asia", "h": ["ff9933", "ffffff", "138808"], "art": [["disc", 30, 20, 5.4, "000080"], ["disc", 30, 20, 4.2, "ffffff"], ["disc", 30, 20, 1.4, "000080"]]},
	{"id": "id", "name": "Indonesia", "rarity": "free", "region": "asia", "h": ["ff0000", "ffffff"]},
	{"id": "th", "name": "Thailand", "rarity": "free", "region": "asia", "h": ["a51931", "f4f5f8", "2d2a4a", "2d2a4a", "f4f5f8", "a51931"]},
	{"id": "vn", "name": "Vietnam", "rarity": "free", "region": "asia", "h": ["da251d"], "art": [["star", 30, 20, 12, "ffff00"]]},
	{"id": "my", "name": "Malaysia", "rarity": "free", "region": "asia", "h": ["cc0001", "ffffff", "cc0001", "ffffff", "cc0001", "ffffff", "cc0001"], "art": [["rect", 0, 0, 30, 23, "010066"], ["moon", 12, 11.5, 7.5, "ffcc00"], ["star", 21, 11.5, 4, "ffcc00"]]},
	{"id": "sg", "name": "Singapore", "rarity": "free", "region": "asia", "h": ["ed2939", "ffffff"], "art": [["moon", 12, 10, 7, "ffffff"], ["ring", 5, 19, 10, 4, 1.3, "ffffff"]]},
	{"id": "pk", "name": "Pakistan", "rarity": "free", "region": "asia", "h": ["01411c"], "art": [["rect", 0, 0, 15, 40, "ffffff"], ["moon", 36, 20, 11, "ffffff"], ["star", 43, 15, 4, "ffffff"]]},
	{"id": "bd", "name": "Bangladesh", "rarity": "free", "region": "asia", "h": ["006a4e"], "art": [["disc", 27, 20, 12, "f42a41"]]},
	{"id": "ae", "name": "UAE", "rarity": "free", "region": "asia", "h": ["00732f", "ffffff", "0a1426"], "art": [["rect", 0, 0, 15, 40, "ff0000"]]},
	{"id": "tr", "name": "Turkiye", "rarity": "free", "region": "asia", "h": ["e30a17"], "art": [["moon", 23, 20, 10, "ffffff"], ["star", 37, 20, 5, "ffffff"]]},
	{"id": "il", "name": "Israel", "rarity": "free", "region": "asia", "h": ["ffffff"], "art": [["rect", 0, 5, 60, 5, "0038b8"], ["rect", 0, 30, 60, 5, "0038b8"], ["path", "M30 12 L37 24 H23 Z M30 28 L23 16 H37 Z", "0038b8"], ["path", "M30 15 L34.4 22.5 H25.6 Z M30 25 L25.6 17.5 H34.4 Z", "ffffff"]]},
	{"id": "ps", "name": "Palestine", "rarity": "free", "region": "asia", "h": ["0a1426", "ffffff", "009736"], "art": [["tri", 0, 0, 22, 20, 0, 40, "ce1126"]]},
	{"id": "lb", "name": "Lebanon", "rarity": "free", "region": "asia", "h": ["ed1c24", "ffffff", "ffffff", "ed1c24"], "art": [["path", "M30 11 L37 20 H34 L39 26 H21 L26 20 H23 Z", "00a651"], ["rect", 28.8, 26, 2.4, 3, "00a651"]]},
	# Europe
	{"id": "gb", "name": "United Kingdom", "rarity": "free", "region": "europe", "h": ["012169"], "art": [["saltire", 7, "ffffff"], ["saltire", 2.6, "c8102e"], ["cross", 30, 20, 12, "ffffff"], ["cross", 30, 20, 7, "c8102e"]]},
	{"id": "fr", "name": "France", "rarity": "free", "region": "europe", "v": ["0055a4", "ffffff", "ef4135"]},
	{"id": "de", "name": "Germany", "rarity": "free", "region": "europe", "h": ["0a1426", "dd0000", "ffce00"]},
	{"id": "it", "name": "Italy", "rarity": "free", "region": "europe", "v": ["009246", "ffffff", "ce2b37"]},
	{"id": "es", "name": "Spain", "rarity": "free", "region": "europe", "h": ["aa151b", "f1bf00", "f1bf00", "aa151b"]},
	{"id": "pt", "name": "Portugal", "rarity": "free", "region": "europe", "h": ["ff0000"], "art": [["rect", 0, 0, 24, 40, "006600"], ["disc", 24, 20, 8, "ffcc00"], ["disc", 24, 20, 4.4, "ff0000"], ["disc", 24, 20, 2.6, "ffffff"]]},
	{"id": "nl", "name": "Netherlands", "rarity": "free", "region": "europe", "h": ["ae1c28", "ffffff", "21468b"]},
	{"id": "be", "name": "Belgium", "rarity": "free", "region": "europe", "v": ["0a1426", "fae042", "ed2939"]},
	{"id": "ch", "name": "Switzerland", "rarity": "free", "region": "europe", "h": ["d52b1e"], "art": [["cross", 30, 20, 7, "ffffff", 13]]},
	{"id": "at", "name": "Austria", "rarity": "free", "region": "europe", "h": ["ed2939", "ffffff", "ed2939"]},
	{"id": "se", "name": "Sweden", "rarity": "free", "region": "europe", "h": ["006aa7"], "art": [["cross", 21, 20, 7, "fecc00"]]},
	{"id": "no", "name": "Norway", "rarity": "free", "region": "europe", "h": ["ba0c2f"], "art": [["cross", 21, 20, 9, "ffffff"], ["cross", 21, 20, 4.6, "00205b"]]},
	{"id": "dk", "name": "Denmark", "rarity": "free", "region": "europe", "h": ["c8102e"], "art": [["cross", 21, 20, 6, "ffffff"]]},
	{"id": "fi", "name": "Finland", "rarity": "free", "region": "europe", "h": ["ffffff"], "art": [["cross", 21, 20, 9, "003580"]]},
	{"id": "is", "name": "Iceland", "rarity": "free", "region": "europe", "h": ["02529c"], "art": [["cross", 21, 20, 9, "ffffff"], ["cross", 21, 20, 4.6, "dc1e35"]]},
	{"id": "ie", "name": "Ireland", "rarity": "free", "region": "europe", "v": ["169b62", "ffffff", "ff883e"]},
	{"id": "pl", "name": "Poland", "rarity": "free", "region": "europe", "h": ["ffffff", "dc143c"]},
	{"id": "gr", "name": "Greece", "rarity": "free", "region": "europe", "h": ["0d5eaf", "ffffff", "0d5eaf", "ffffff", "0d5eaf", "ffffff", "0d5eaf", "ffffff", "0d5eaf"], "art": [["rect", 0, 0, 22, 22, "0d5eaf"], ["rect", 8.8, 0, 4.4, 22, "ffffff"], ["rect", 0, 8.8, 22, 4.4, "ffffff"]]},
	{"id": "ua", "name": "Ukraine", "rarity": "free", "region": "europe", "h": ["0057b7", "ffd700"]},
	{"id": "ru", "name": "Russia", "rarity": "free", "region": "europe", "h": ["ffffff", "0039a6", "d52b1e"]},
	{"id": "cz", "name": "Czechia", "rarity": "free", "region": "europe", "h": ["ffffff", "d7141a"], "art": [["tri", 0, 0, 30, 20, 0, 40, "11457e"]]},
	{"id": "hu", "name": "Hungary", "rarity": "free", "region": "europe", "h": ["ce2939", "ffffff", "477050"]},
	{"id": "ro", "name": "Romania", "rarity": "free", "region": "europe", "v": ["002b7f", "fcd116", "ce1126"]},
	{"id": "bg", "name": "Bulgaria", "rarity": "free", "region": "europe", "h": ["ffffff", "00966e", "d62612"]},
	{"id": "ee", "name": "Estonia", "rarity": "free", "region": "europe", "h": ["0072ce", "0a1426", "ffffff"]},
	{"id": "lv", "name": "Latvia", "rarity": "free", "region": "europe", "h": ["9e3039", "9e3039", "ffffff", "9e3039", "9e3039"]},
	{"id": "lt", "name": "Lithuania", "rarity": "free", "region": "europe", "h": ["fdb913", "006a44", "c1272d"]},
	# The Americas
	{"id": "us", "name": "United States", "rarity": "free", "region": "americas", "h": ["b22234", "ffffff", "b22234", "ffffff", "b22234", "ffffff", "b22234", "ffffff", "b22234", "ffffff", "b22234", "ffffff", "b22234"], "art": [["rect", 0, 0, 26, 21.5, "3c3b6e"], ["star", 5, 5, 2, "ffffff"], ["star", 13, 5, 2, "ffffff"], ["star", 21, 5, 2, "ffffff"], ["star", 9, 11, 2, "ffffff"], ["star", 17, 11, 2, "ffffff"], ["star", 5, 17, 2, "ffffff"], ["star", 13, 17, 2, "ffffff"], ["star", 21, 17, 2, "ffffff"]]},
	{"id": "ca", "name": "Canada", "rarity": "free", "region": "americas", "h": ["ffffff"], "art": [["rect", 0, 0, 15, 40, "d80621"], ["rect", 45, 0, 15, 40, "d80621"], ["path", "M30 8 l2.5 4.5 l3 -1.5 l-1 6 l4 -2 l1 3 l4 -0.5 l-1.5 4.5 l1.5 1 l-6 4.5 l0.6 2.5 l-6.1 -0.6 v4.6 h-2 v-4.6 l-6.1 0.6 l0.6 -2.5 l-6 -4.5 l1.5 -1 l-1.5 -4.5 l4 0.5 l1 -3 l4 2 l-1 -6 l3 1.5 Z", "d80621"]]},
	{"id": "mx", "name": "Mexico", "rarity": "free", "region": "americas", "v": ["006847", "ffffff", "ce1126"], "art": [["disc", 30, 20, 5.5, "a0642c"], ["disc", 30, 21, 2.8, "7a4a22"], ["path", "M25 24 Q30 28 35 24 L34 26.5 Q30 29 26 26.5 Z", "006847"]]},
	{"id": "br", "name": "Brazil", "rarity": "free", "region": "americas", "h": ["009739"], "art": [["path", "M30 4 L56 20 L30 36 L4 20 Z", "fedd00"], ["disc", 30, 20, 9.5, "012169"], ["path", "M21 18 Q30 16 39.3 22 L39 23.8 Q30 18 20.8 20 Z", "ffffff"]]},
	{"id": "ar", "name": "Argentina", "rarity": "free", "region": "americas", "h": ["74acdf", "ffffff", "74acdf"], "art": [["disc", 30, 20, 4.4, "f6b40e"], ["disc", 30, 20, 3, "e0950c"]]},
	{"id": "co", "name": "Colombia", "rarity": "free", "region": "americas", "h": ["fcd116", "fcd116", "003893", "ce1126"]},
	{"id": "cl", "name": "Chile", "rarity": "free", "region": "americas", "h": ["ffffff", "d52b1e"], "art": [["rect", 0, 0, 20, 20, "0039a6"], ["star", 10, 10, 6.5, "ffffff"]]},
	{"id": "pe", "name": "Peru", "rarity": "free", "region": "americas", "v": ["d91023", "ffffff", "d91023"]},
	{"id": "ve", "name": "Venezuela", "rarity": "free", "region": "americas", "h": ["fcd116", "00247d", "cf142b"], "art": [["ring", 8, 30, 25, 9, 1.0, "ffffff"]]},
	{"id": "uy", "name": "Uruguay", "rarity": "free", "region": "americas", "h": ["ffffff", "0038a8", "ffffff", "0038a8", "ffffff", "0038a8", "ffffff", "0038a8", "ffffff"], "art": [["rect", 0, 0, 22, 22, "ffffff"], ["disc", 11, 11, 6, "fcd116"]]},
	{"id": "cu", "name": "Cuba", "rarity": "free", "region": "americas", "h": ["002a8f", "ffffff", "002a8f", "ffffff", "002a8f"], "art": [["tri", 0, 0, 30, 20, 0, 40, "cf142b"], ["star", 10, 20, 6, "ffffff"]]},
	{"id": "jm", "name": "Jamaica", "rarity": "free", "region": "americas", "h": ["009b3a"], "art": [["tri", 0, 0, 26, 20, 0, 40, "0a1426"], ["tri", 60, 0, 34, 20, 60, 40, "0a1426"], ["saltire", 5, "fed100"]]},
	{"id": "cr", "name": "Costa Rica", "rarity": "free", "region": "americas", "h": ["002b7f", "ffffff", "ce1126", "ce1126", "ffffff", "002b7f"]},
	{"id": "pa", "name": "Panama", "rarity": "free", "region": "americas", "h": ["ffffff"], "art": [["rect", 30, 0, 30, 20, "d21034"], ["rect", 0, 20, 30, 20, "005293"], ["star", 15, 10, 5, "005293"], ["star", 45, 30, 5, "d21034"]]},
	{"id": "bo", "name": "Bolivia", "rarity": "free", "region": "americas", "h": ["d52b1e", "f9e300", "007934"]},
	# Africa
	{"id": "ng", "name": "Nigeria", "rarity": "free", "region": "africa", "v": ["008751", "ffffff", "008751"]},
	{"id": "za", "name": "South Africa", "rarity": "free", "region": "africa", "h": ["de3831", "ffffff", "002395"], "art": [["path", "M0 0 L26 20 L0 40 Z", "ffffff"], ["path", "M0 5 L19.5 20 L0 35 Z", "0a1426"], ["path", "M0 0 H8 L33 13 H60 V27 H33 L8 40 H0 L24 20 Z", "ffffff"], ["path", "M0 3 L28 16 H60 V24 H28 L0 37 V33 L20.6 20 L0 7 Z", "007749"], ["path", "M0 7 L20.6 20 L0 33 Z", "ffb81c"], ["path", "M0 11 L15.5 20 L0 29 Z", "0a1426"]]},
	{"id": "ke", "name": "Kenya", "rarity": "free", "region": "africa", "h": ["0a1426", "ffffff", "bb0000", "bb0000", "ffffff", "006600"], "art": [["path", "M30 7 Q37 20 30 33 Q23 20 30 7 Z", "bb0000"], ["rect", 29, 15, 2, 10, "ffffff"]]},
	{"id": "eg", "name": "Egypt", "rarity": "free", "region": "africa", "h": ["ce1126", "ffffff", "0a1426"], "art": [["path", "M30 15.5 L33 18 L33 23 L30 25 L27 23 L27 18 Z", "c09300"]]},
	{"id": "ma", "name": "Morocco", "rarity": "free", "region": "africa", "h": ["c1272d"], "art": [["path", "M30 9 L36.6 29 L19.5 16.6 H40.5 L23.4 29 Z", "006233", "none", 1.5]]},
	{"id": "gh", "name": "Ghana", "rarity": "free", "region": "africa", "h": ["ce1126", "fcd116", "006b3f"], "art": [["star", 30, 20, 6.5, "0a1426"]]},
	{"id": "et", "name": "Ethiopia", "rarity": "free", "region": "africa", "h": ["078930", "fcdd09", "da121a"], "art": [["disc", 30, 20, 9, "0f47af"], ["star", 30, 20, 7, "fcdd09"]]},
	{"id": "sn", "name": "Senegal", "rarity": "free", "region": "africa", "v": ["00853f", "fdef42", "e31b23"], "art": [["star", 30, 20, 5.5, "00853f"]]},
	{"id": "tz", "name": "Tanzania", "rarity": "free", "region": "africa", "h": ["1eb53a"], "art": [["tri", 60, 0, 60, 40, 0, 40, "00a3dd"], ["path", "M0 40 L0 30 L46 0 L60 0 L60 10 L14 40 Z", "fcd116"], ["path", "M0 40 L0 34 L52 0 L60 0 L60 6 L8 40 Z", "0a1426"]]},
	{"id": "cm", "name": "Cameroon", "rarity": "free", "region": "africa", "v": ["007a5e", "ce1126", "fcd116"], "art": [["star", 30, 20, 4.5, "fcd116"]]},
	{"id": "dz", "name": "Algeria", "rarity": "free", "region": "africa", "v": ["006233", "ffffff"], "art": [["moon", 30, 20, 9, "d21034"], ["star", 34, 20, 5, "d21034"]]},
	{"id": "tn", "name": "Tunisia", "rarity": "free", "region": "africa", "h": ["e70013"], "art": [["disc", 30, 20, 10, "ffffff"], ["moon", 29, 20, 7, "e70013"], ["star", 32, 20, 3.6, "e70013"]]},
	{"id": "ci", "name": "Ivory Coast", "rarity": "free", "region": "africa", "v": ["f77f00", "ffffff", "009e60"]},
	{"id": "ml", "name": "Mali", "rarity": "free", "region": "africa", "v": ["14b53a", "fcd116", "ce1126"]},
	{"id": "bw", "name": "Botswana", "rarity": "free", "region": "africa", "h": ["6da9d2", "6da9d2", "ffffff", "0a1426", "0a1426", "ffffff", "6da9d2", "6da9d2"]},
	# Oceania
	{"id": "au", "name": "Australia", "rarity": "free", "region": "oceania", "h": ["012169"], "art": [["path", "M0 0 L30 20 M30 0 L0 20", "ffffff", "line", 4], ["path", "M0 0 L30 20 M30 0 L0 20", "c8102e", "line", 1.6], ["path", "M15 0 V20 M0 10 H30", "ffffff", "line", 6], ["path", "M15 0 V20 M0 10 H30", "c8102e", "line", 3.2], ["star", 15, 30, 5, "ffffff"], ["star", 46, 7, 2.3, "ffffff"], ["star", 46, 33, 2.3, "ffffff"], ["star", 39, 18, 2.3, "ffffff"], ["star", 53, 16, 2.3, "ffffff"]]},
	{"id": "nz", "name": "New Zealand", "rarity": "free", "region": "oceania", "h": ["012169"], "art": [["path", "M0 0 L30 20 M30 0 L0 20", "ffffff", "line", 4], ["path", "M0 0 L30 20 M30 0 L0 20", "c8102e", "line", 1.6], ["path", "M15 0 V20 M0 10 H30", "ffffff", "line", 6], ["path", "M15 0 V20 M0 10 H30", "c8102e", "line", 3.2], ["star", 46, 8, 2.8, "cc142b"], ["star", 46, 32, 2.8, "cc142b"], ["star", 40, 18, 2.8, "cc142b"], ["star", 52, 16, 2.4, "cc142b"]]},
	{"id": "ws", "name": "Samoa", "rarity": "free", "region": "oceania", "h": ["ce1126"], "art": [["rect", 0, 0, 28, 20, "002b7f"], ["star", 14, 5, 2.4, "ffffff"], ["star", 8, 10, 2.4, "ffffff"], ["star", 20, 9, 2.4, "ffffff"], ["star", 14, 15, 2.4, "ffffff"]]},
	# Just for fun
	{"id": "pirate", "name": "Pirate Flag", "rarity": "rare", "region": "fun", "h": ["0a1426"], "art": [["disc", 30, 17, 8, "ffffff"], ["rect", 25, 21, 10, 6, "ffffff"], ["disc", 27, 16, 2.2, "0a1426"], ["disc", 33, 16, 2.2, "0a1426"], ["path", "M12 28 L48 36 M48 28 L12 36", "ffffff", "line", 3]], "blurb": "Arr. The base is ours now."},
	{"id": "checkered", "name": "Finish Line", "rarity": "common", "region": "fun", "check": ["ffffff", "0a1426"], "blurb": "You've already won. Just ask."},
	{"id": "rainbow", "name": "Rainbow", "rarity": "common", "region": "fun", "h": ["e40303", "ff8c00", "ffed00", "008026", "24408e", "732982"], "blurb": "Every colour, all at once."},
	{"id": "earth", "name": "Planet Earth", "rarity": "rare", "region": "fun", "h": ["0a4fa8"], "art": [["disc", 30, 20, 13, "3aa6ff"], ["path", "M21 11 Q27 9 29 13 Q27 18 23 18 Q19 16 21 11 Z M31 20 Q38 18 40 23 Q37 30 32 29 Q29 25 31 20 Z", "35d07f"]], "blurb": "One team. Well, two teams."},
	{"id": "smiley", "name": "Big Smile", "rarity": "common", "region": "fun", "h": ["ffd23f"], "art": [["disc", 22, 15, 3, "0a1426"], ["disc", 38, 15, 3, "0a1426"], ["path", "M17 23 Q30 37 43 23 Z", "0a1426"]], "blurb": "Hard to be cross at this flag."},
	{"id": "crystal", "name": "Crystal Flag", "rarity": "epic", "region": "fun", "h": ["7f38d6"], "art": [["path", "M30 5 L42 16 L30 36 L18 16 Z", "ff6fb5"], ["path", "M30 5 L36 16 L30 36 L24 16 Z", "7ee8ff"], ["path", "M18 16 H42 L36 16 L30 5 L24 16 Z", "ffffff"]], "blurb": "For those who grab them all."},
	{"id": "cat", "name": "Cat Flag", "rarity": "rare", "region": "fun", "h": ["ff9d2e"], "art": [["path", "M17 15 L19 5 L26 10 H34 L41 5 L43 15 Q45 32 30 33 Q15 32 17 15 Z", "fff6dd"], ["disc", 24, 19, 2.3, "0a1426"], ["disc", 36, 19, 2.3, "0a1426"], ["path", "M30 22 L28 25 H32 Z", "ff6fb5"]], "blurb": "Knocks other flags off tables."},
	{"id": "pizza", "name": "Pizza Flag", "rarity": "rare", "region": "fun", "h": ["35d07f"], "art": [["path", "M30 36 L12 6 Q30 0 48 6 Z", "ffd23f"], ["path", "M12 6 Q30 0 48 6 L46 10 Q30 4 14 10 Z", "c98c4a"], ["disc", 27, 14, 3, "e8483f"], ["disc", 36, 15, 3, "e8483f"], ["disc", 31, 24, 3, "e8483f"]], "blurb": "A nation of one topping."},
	{"id": "gold", "name": "Solid Gold", "rarity": "legend", "region": "fun", "h": ["ffc21f", "ffe27a", "ffc21f"], "art": [["star", 30, 20, 12, "fff6c9"]], "blurb": "It's heavy. Worth it."},
]

const REGIONS := {"asia": "Asia", "europe": "Europe", "americas": "Americas", "africa": "Africa", "oceania": "Oceania", "fun": "Fun"}

static var _textures := {}


## A flag on a white rim with a dark edge, so it stands out on any floor or panel.
static func svg(id: String, framed := true) -> String:
	var def := Cosmetics.item("flag", id)
	var out := ""
	if def.has("h"):
		var rows: Array = def["h"]
		for i in rows.size():
			out += _rect(0, i * 40.0 / rows.size(), 60, 40.0 / rows.size() + 0.2, rows[i])
	if def.has("v"):
		var cols: Array = def["v"]
		for i in cols.size():
			out += _rect(i * 60.0 / cols.size(), 0, 60.0 / cols.size() + 0.2, 40, cols[i])
	if def.has("check"):
		var pair: Array = def["check"]
		for y in 4:
			for x in 6:
				out += _rect(x * 10.0, y * 10.0, 10.1, 10.1, pair[(x + y) % 2])
	for piece: Array in def.get("art", []):
		out += _piece(piece)
	if not framed:
		return "<svg xmlns='http://www.w3.org/2000/svg' width='120' height='80' viewBox='0 0 60 40'>%s</svg>" % out
	return ("<svg xmlns='http://www.w3.org/2000/svg' width='132' height='92' viewBox='-3 -3 66 46'>"
		+ "<rect x='-3' y='-3' width='66' height='46' rx='6' fill='#0a1426'/><rect x='-1.5' y='-1.5' width='63' height='43' rx='4.5' fill='#ffffff'/>"
		+ "<clipPath id='c'><rect width='60' height='40' rx='3'/></clipPath><g clip-path='url(#c)'>%s</g></svg>") % out


static func _rect(x: float, y: float, w: float, h: float, c: String) -> String:
	return "<rect x='%s' y='%s' width='%s' height='%s' fill='#%s'/>" % [x, y, w, h, c]


static func _star_points(x: float, y: float, r: float) -> String:
	var pts: Array[String] = []
	for i in 10:
		var a := -PI * 0.5 + PI * i / 5.0
		var reach := r if i % 2 == 0 else r * 0.42
		pts.append("%.2f,%.2f" % [x + cos(a) * reach, y + sin(a) * reach])
	return " ".join(pts)


static func _piece(p: Array) -> String:
	match String(p[0]):
		"disc":
			return "<circle cx='%s' cy='%s' r='%s' fill='#%s'/>" % [p[1], p[2], p[3], p[4]]
		"star":
			return "<polygon points='%s' fill='#%s'/>" % [_star_points(p[1], p[2], p[3]), p[4]]
		"rect":
			return _rect(p[1], p[2], p[3], p[4], p[5])
		"tri":
			return "<polygon points='%s,%s %s,%s %s,%s' fill='#%s'/>" % [p[1], p[2], p[3], p[4], p[5], p[6], p[7]]
		"cross":
			return _cross(p)
		"saltire":
			return "<path d='M0 0 L60 40 M60 0 L0 40' stroke='#%s' stroke-width='%s' fill='none'/>" % [p[2], p[1]]
		"moon":
			# Two arcs that meet at the crescent's points.
			var r := float(p[3])
			var inner := r * 0.8
			var along := 0.783 * r
			var up := 0.622 * r
			var x := float(p[1]) + along
			var y := float(p[2])
			return "<path d='M%.2f %.2f A%.2f %.2f 0 1 0 %.2f %.2f A%.2f %.2f 0 1 1 %.2f %.2f Z' fill='#%s'/>" % [x, y - up, r, r, x, y + up, inner, inner, x, y - up, p[4]]
		"ring":
			var out := ""
			for i in int(p[1]):
				var a := -PI * 0.5 + TAU * i / float(p[1])
				out += "<polygon points='%s' fill='#%s'/>" % [_star_points(float(p[2]) + cos(a) * float(p[4]), float(p[3]) + sin(a) * float(p[4]), p[5]), p[6]]
			return out
		"path":
			if p.size() > 3 and String(p[3]) == "line":
				return "<path d='%s' stroke='#%s' stroke-width='%s' stroke-linecap='round' fill='none'/>" % [p[1], p[2], p[4]]
			if p.size() > 3 and String(p[3]) == "none":
				return "<path d='%s' stroke='#%s' stroke-width='%s' stroke-linejoin='round' fill='none'/>" % [p[1], p[2], p[4]]
			return "<path d='%s' fill='#%s'/>" % [p[1], p[2]]
	return ""


## An upright and a crossbar, meeting at (x, y). The fifth entry, if there is one, keeps it inside a square.
static func _cross(p: Array) -> String:
	var x := float(p[1])
	var y := float(p[2])
	var thick := float(p[3])
	var colour := String(p[4])
	if p.size() > 5:
		var half := float(p[5])
		return _rect(x - thick * 0.5, y - half, thick, half * 2.0, colour) + _rect(x - half, y - thick * 0.5, half * 2.0, thick, colour)
	return _rect(x - thick * 0.5, 0, thick, 40, colour) + _rect(0, y - thick * 0.5, 60, thick, colour)


static func texture(id: String, framed := true) -> Texture2D:
	var key := "%s|%s" % [id, framed]
	if not _textures.has(key):
		var image := Image.new()
		image.load_svg_from_string(svg(id, framed), 1.0)
		image.generate_mipmaps()
		_textures[key] = ImageTexture.create_from_image(image)
	return _textures[key]


## The country a device says it's in, if we have that flag: a good first guess at yours.
static func from_locale(locale: String) -> String:
	var parts := locale.replace("-", "_").split("_")
	if parts.size() < 2:
		return ""
	var id := parts[1].to_lower().left(2)
	return id if not Cosmetics.item("flag", id).is_empty() else ""
