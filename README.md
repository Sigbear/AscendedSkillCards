# AscendedSkillCards
### A quality of life addon that helps with handling and processing skill cards.

#### Features:
* Simplify learning, upgrading and exchanging skill cards with a compact GUI.
* When you open a sealed card the GUI will show automatically and inform you of your current count for (non-golden) skill cards.
* Shows card counter of each rarity so you can easily see if you can upgrade to a higher rarity.
* Buttons to upgrade and exchange cards more easily (use while skill card npc dialogue is open.) 
* Options menu to customize addon behaviour

#### To install:
Download [AscendedSkillCards.7z](https://github.com/Sigbear/AscendedSkillCards/releases/download/1.1.0/AscendedSkillCards.7z) -> extract the AscendedSkillCards folder and put it in your addons folder.

#### Usage:  
The GUI can be toggled with the command /asc and will by default pop up automatically  
As you open sealed decks, any unknown cards will be displayed in a list at the bottom of the GUI which expands as the list grows.  
Left click any of the unknown cards to learn it.  
| ![unknown card](https://user-images.githubusercontent.com/8190851/188265168-099db9a9-9810-4c69-9122-74d1d23e7975.png) |
|:--:|
| *Any unknown cards will be listed in the gui, so you can easily see and click it* |

## Buttons
| ![gossipButtons](https://user-images.githubusercontent.com/8190851/194095909-e0be7f9c-bb96-43e0-b323-624675dfd101.png) |
|:--:|
| *GUI with shiny buttons!* |

There are two buttons available to make upgrading and exchanging a lot of skill cards easier.  
The upgrade button can be clicked to upgrade cards from lowest highest rarity when possible, i.e. uncommon -> rare -> epic.  
The exchange button turns in 5 random cards for you when clicked.  
For the buttons to work as intended **you must have the npc skill card dialogue open when clicking.**


#### Known issues:  
tl:dr reload ui with /rl  
* Occasionally the addon will insist that all of your skill cards are unknown, this is server related and fixed with a ui reload (like most other things)
