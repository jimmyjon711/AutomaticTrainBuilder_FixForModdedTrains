
game.players[1].print("Welcome to 0.16 with the Automatic Train Builder Mod. It is now necessary to hook the creator chest up to a constant combinator. Request loco/wagon in desired build. E.G. 1 Loco, 3 Wagons, 1 Loco. The builder chest can now just be set to get requests from the circuit network")
for _, force in pairs(game.forces) do
  force.reset_recipes()
  force.reset_technologies()

  -- create tech/recipe table once
  local techs = force.technologies
  local recipes = force.recipes
  if techs["logistic-system"].researched then
    recipes["train-creator-chest"].enabled = true
  end
end