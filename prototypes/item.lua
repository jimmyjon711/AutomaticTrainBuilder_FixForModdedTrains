local item = copyPrototype("item","logistic-chest-requester", "train-creator-chest")

local recipe = copyPrototype("recipe","logistic-chest-requester", "train-creator-chest")

recipe.enabled = false

local train_creator_chest = copyPrototype("logistic-container", "logistic-chest-requester", "train-creator-chest")

table.insert(data.raw["technology"]["logistic-system"].effects,{type="unlock-recipe",recipe="train-creator-chest"})

data:extend({train_creator_chest,item, recipe})

