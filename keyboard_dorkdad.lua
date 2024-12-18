--- STEAMODDED HEADER
--- MOD_NAME: Keyboard Shortcuts DorkDad
--- MOD_ID: keyboard_dorkdad
--- MOD_AUTHOR: [DorkDad141]
--- MOD_DESCRIPTION: Add keyboard shortcuts to the game
----------------------------------------------
------------MOD CODE -------------------------

local suits = { 'Hearts', 'Clubs', 'Diamonds', 'Spades'}

local keyupdate_ref = Controller.key_press_update
function Controller.key_press_update(self, key, dt)
    keyupdate_ref(self, key, dt)
    keys_to_nums = {
        ["2"] = 2,
        ["3"] = 3,
        ["4"] = 4,
        ["5"] = 5,
        ["6"] = 6,
        ["7"] = 7,
        ["8"] = 8,
        ["9"] = 9,
        ["0"] = 10,
        ["1"] = 10,
        ["j"] = 11,
        ["q"] = 12,
        ["k"] = 13,
        ["a"] = 14,
    }
    keys_to_ui = {
        ["z"] = "sort_value",
        ["x"] = "sort_rank",
        ["space"] = "play_hand",
        ["tab"] = "discard_hand",
        ["a"] = "run_info",

        ["h"] = "flush",
        ["d"] = "flush",
        ["c"] = "flush",
        ["s"] = "flush",
        ["f"] = "best_flush",

        ["up"] = "high_card",
        ["down"] = "high_card",
    }

    keys_to_suit = {
        ["s"] = "Spades",
        ["d"] = "Diamonds",
        ["c"] = "Clubs",
        ["h"] = "Hearts",
    }

    if G.STATE == G.STATES.ROUND_EVAL then
        if key == "space" then
       --     G.FUNCS.cash_out(G.shop:get_UIE_by_ID('cash_out_button'))
        end
    elseif G.STATE == G.STATES.BLIND_SELECT then
        if key == "space" then
       --     G.FUNCS.toggle_shop(1)
        elseif key == "s" then
       --     G.FUNCS.skip_blind(G.shop:get_UIE_by_ID('skip_blind'))
        end

    elseif G.STATE == G.STATES.SHOP then
        if key == "r" and not ((G.GAME.dollars-G.GAME.bankrupt_at) - G.GAME.current_round.reroll_cost < 0) and G.GAME.current_round.reroll_cost ~= 0 then
            G.FUNCS.reroll_shop(1)
        elseif key == "space" then
            G.FUNCS.toggle_shop(1)
        end


    elseif G.STATE == G.STATES.SELECTING_HAND then
        if tableContains(keys_to_nums, key) then
            num = keys_to_nums[key]
            select_by_rank(num)
        elseif tableContains(keys_to_ui, key) then
            if keys_to_ui[key] == "play_hand" then
                local play_button = G.buttons:get_UIE_by_ID('play_button')
                if play_button.config.button == 'play_cards_from_highlighted' then
                    G.FUNCS.play_cards_from_highlighted()
                end
            elseif keys_to_ui[key] == "best_flush" then
                flush(best_flush_suit())
            elseif keys_to_ui[key] == "flush" then
                flush(keys_to_suit[key])
            elseif keys_to_ui[key] == "high_card" then
                high_card(key)
            elseif keys_to_ui[key] == "discard_hand" then
                local discard_button = G.buttons:get_UIE_by_ID('discard_button')
                if discard_button.config.button == 'discard_cards_from_highlighted' then
                    G.FUNCS.discard_cards_from_highlighted()
                end
            elseif keys_to_ui[key] == "sort_value" then
                G.FUNCS.sort_hand_value()
            elseif keys_to_ui[key] == "sort_rank" then
                G.FUNCS.sort_hand_suit()
            elseif keys_to_ui[key] == "run_info" then
                local run_info_button = G.HUD:get_UIE_by_ID('run_info_button')
                if run_info_button.config.button == 'run_info' then
                    G.FUNCS.run_info()
                end
            end
        elseif key == "b" then
            local best_hands = ranked_hands(G.hand.cards)
            select_hand(next_best_oak(best_hands, G.hand.highlighted))
        elseif key == "i" or key == "v" then
            invert_selection()
            discard_or_play()
        elseif key == "u" or key == "n" then
            G.hand:unhighlight_all()
        elseif key == "left" then
            left5()
        elseif key == "right" then
            right5()
        elseif key == "m" then
            for i = 1, 2 do
              local card = create_card('Tarot', G.consumeables, nil, nil, nil, nil, 'c_death', 'emp')
              -- card:add_to_deck()
              -- G.consumeables:emplace(card)
            end
        end
    end
end

function left5()
  G.hand:unhighlight_all()
  for i = 1, 5 do
      if i > #G.hand.cards then break end
      card = G.hand.cards[i]
      G.hand:add_to_highlighted(card, true)
  end
end

function right5()
  G.hand:unhighlight_all()
  for i = #G.hand.cards, #G.hand.cards-5,-1 do
      if i < 1 then break end
      card = G.hand.cards[i]
      G.hand:add_to_highlighted(card, true)
  end
end

-- check if a list has a value in it
local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function next_best_oak(possible_hands, curr_hand)
  if #possible_hands == 1 then
    return possible_hands[1]
  end
  if #possible_hands == 0 then
    return {}
  end
  for i = 1, (#possible_hands - 1) do
    if are_ranks_same(possible_hands[i], curr_hand) then
      return possible_hands[i + 1]
    end
  end
  return possible_hands[1]
end

function ranked_hands(cards)
    local fives, fours, trips, twos = {}, {}, {}, {}
    local rank_counts = {}
    local four_fingers = next(find_joker("Four Fingers"))
    local smeared_joker = next(find_joker("Smeared Joker"))
    -- local shortcut = next(find_joker('Shortcut'))

    for i, card in pairs(cards) do
        local rank = get_visible_rank(card)
        if not (rank == "stone") then
            if not rank_counts[rank] then
                rank_counts[rank] = {}
            end
            table.insert(rank_counts[rank], card)
        end
    end
    for k, v in pairs(rank_counts) do
        table.sort(v, function(x, y)
            return calculate_importance(x, true) > calculate_importance(y, true)
        end)
        if #v >= 5 then
            table.insert(fives, take(v, 5))
        end
        if #v >= 4 then
            table.insert(fours, take(v, 4))
        end
        if #v >= 3 then
            table.insert(trips, take(v, 3))
        end
        if #v >= 2 then
            table.insert(twos, take(v, 2))
        end
    end

    local full_houses = {}
    for i = 1, #trips do
        for j = 1, #twos do
            if get_visible_rank(trips[i][1]) ~= get_visible_rank(twos[j][1]) then
                table.insert(full_houses, merge(trips[i], twos[j]))
            end
        end
    end

    local two_pairs = {}
    for i = 1, (#twos - 1) do
        for j = i + 1, #twos do
            table.insert(two_pairs, add_stone(merge(twos[i], twos[j])))
        end
    end

    -- add stone cards to hands
    for i = 1, #twos do
        twos[i] = add_stone(twos[i])
    end
    for i = 1, #trips do
        trips[i] = add_stone(trips[i])
    end
    for i = 1, #fours do
        fours[i] = add_stone(fours[i])
    end

    local straights = {}
    for i = 1, 10 do
        has_straight = 1
        straight = {}
        for j = i, i + 4 do
            actual_rank = j
            if j == 1 then
                actual_rank = 14
            end -- handle The Wheel blind
            if rank_counts[actual_rank] then
                table.insert(straight, rank_counts[actual_rank][1])
            elseif four_fingers and rank_counts[actual_rank - 1] then
                table.insert(straight, rank_counts[actual_rank - 1][1])
            else
                has_straight = 0
                break
            end
        end

        if has_straight == 1 then
            table.insert(straights, straight)
        end
    end

    local cards_by_suit = (
        smeared_joker
        and {
            sorted_cards_by_suit("Spades", "Clubs"),
            sorted_cards_by_suit("Hearts", "Diamonds"),
        }
    )
        or {
            sorted_cards_by_suit(suits[1]),
            sorted_cards_by_suit(suits[2]),
            sorted_cards_by_suit(suits[3]),
            sorted_cards_by_suit(suits[4]),
        }

    local flushes = {}
    for _, sorted_flush in ipairs(cards_by_suit) do
        if #sorted_flush >= 5 then
            table.insert(flushes, take(sorted_flush, 5))
        end
        if four_fingers and #sorted_flush >= 4 then
            table.insert(flushes, take(sorted_flush, 4))
        end
    end

    table.sort(fives, function(x, y)
        return hand_importance(x) > hand_importance(y)
    end)
    table.sort(fours, function(x, y)
        return hand_importance(x) > hand_importance(y)
    end)
    table.sort(flushes, function(x, y)
        return hand_importance(x) > hand_importance(y)
    end)
    table.sort(straights, function(x, y)
        return hand_importance(x) > hand_importance(y)
    end)
    table.sort(trips, function(x, y)
        return hand_importance(x) > hand_importance(y)
    end)
    table.sort(full_houses, function(x, y)
        return hand_importance(x) > hand_importance(y)
    end)
    table.sort(two_pairs, function(x, y)
        return hand_importance(x) > hand_importance(y)
    end)
    table.sort(twos, function(x, y)
        return hand_importance(x) > hand_importance(y)
    end)
    local res = {}
    res = merge(res, fives)
    res = merge(res, fours)
    res = merge(res, full_houses)
    res = merge(res, flushes)
    res = merge(res, straights)
    res = merge(res, trips)
    res = merge(res, two_pairs)
    res = merge(res, twos)
    return res
end

-- add as many stones as will fit into the current set of cards
function add_stone(cards)
  for i = 1, #G.hand.cards do
    card = G.hand.cards[i]
    if #cards < 5 and get_visible_suit(card) == "stone" then  
       table.insert(cards, card)
    end
  end
  return cards
end

function invert_selection()
  local unselected = filter(G.hand.cards, function(x)
    return -1 == indexOf(G.hand.highlighted,
      function(y) return y == x end)
  end)
  table.sort(unselected, function(x, y) return calculate_importance(x, false) < calculate_importance(y, false) end)
  select_hand(take(unselected, 5))
end

function are_ranks_same(hand1, hand2)
  local h1_ranks = map_f(hand1, get_visible_rank)
  local h2_ranks = map_f(hand2, get_visible_rank)
  local h1_rank_counts = {}
  for i, v in ipairs(h1_ranks) do
    if not h1_rank_counts[v] then
      h1_rank_counts[v] = 0
    end
    h1_rank_counts[v] = h1_rank_counts[v] + 1
  end
  local h2_rank_counts = {}
  for i, v in ipairs(h2_ranks) do
    if not h2_rank_counts[v] then
      h2_rank_counts[v] = 0
    end
    h2_rank_counts[v] = h2_rank_counts[v] + 1
  end
  for k, v in pairs(h1_rank_counts) do
    if not h2_rank_counts[k] then return false end
    if not (h2_rank_counts[k] == v) then return false end
  end
  -- this is a bad solution but this part is not computation intensive anyways
  for k, v in pairs(h2_rank_counts) do
    if not h1_rank_counts[k] then return false end
    if not (h1_rank_counts[k] == v) then return false end
  end
  return true
end

function possible_hands(cards, prop_selector)
  local dictionary = {}
  for i, v in pairs(cards) do
    if not dictionary[prop_selector(v)] then
      dictionary[prop_selector(v)] = {}
    end
  end
  for k, v in pairs(cards) do
    table.insert(dictionary[prop_selector(v)], v)
  end
  local res = {}
  for k, v in pairs(dictionary) do
    table.sort(v, function(x, y) return calculate_importance(x, true) > calculate_importance(y, true) end)
    table.insert(res, take(v, 5))
  end
  table.sort(res, function(x, y)
    return ((#x == #y) and (hand_importance(x) > hand_importance(y)))
        or #x > #y
  end)
  return res
end

function select_hand(cards)
  G.hand:unhighlight_all()
  for k, v in pairs(cards) do
    if indexOf(G.hand.highlighted, function(x) return x == v end) == -1 then
      G.hand:add_to_highlighted(v, true)
    end
  end
  if next(cards) then
    play_sound("cardSlide1")
  else
    play_sound("cancel")
  end
end

function high_card(key)
  G.hand:unhighlight_all()

  min_score = 1000
  max_score = -1000
  min_index = #G.hand.cards
  max_index = 1 
  for i = 1, #G.hand.cards do
    rank = get_visible_rank(G.hand.cards[i])
    if rank ~= 'stone' and rank ~= 'mystery' then
      score = calculate_importance(G.hand.cards[i], true)
      if score > max_score then
        max_score = score
        max_index = i
      end
      if score < min_score then
        min_score = score
        min_index = i
      end
    end
  end

  if key == "down" then
    card = G.hand.cards[min_index]
    G.hand:add_to_highlighted(card)
    G.FUNCS.play_cards_from_highlighted()
  else
    cards = { G.hand.cards[max_index] }
    select_hand(add_stone(cards))
    G.FUNCS.play_cards_from_highlighted()
  end
end

-- given a hand rank (jack=11, queen=12, king=13, ace=14)
-- select all cards in your hand with that rank
function select_by_rank(rank) 
    for i = 1, #G.hand.cards do
        card = G.hand.cards[i]
        if get_visible_rank(card) == rank and not has_value(G.hand.highlighted, card) then
            G.hand:add_to_highlighted(card)
        end
    end
end

function best_flush_suit()
    local best_score = 0
    local score_for_suit = {}
    local best_suit = 'Hearts'
    for i = 1, 4 do
        local suit = suits[i]
        local cards = sorted_cards_by_suit(suit)
        local score = 1000 * #cards
        local importance_score = hand_importance(take(cards, 5))
        score = score + hand_importance(take(cards, 5))
        score_for_suit[suit] = score
        if score > best_score then
            best_score = score
            best_suit = suit
        end
    end
    return best_suit
end

function sorted_cards_by_suit(...)
    local cards = {}
    local count = 0
    local suits = { ... }
    for _, suit in pairs(suits) do
        for i = 1, #G.hand.cards do
            card = G.hand.cards[i]
            if get_visible_suit(card) == suit or get_visible_suit(card) == "Wild" then
                table.insert(cards, card)
                count = count + 1
            end
        end
    end
    table.sort(cards, function(x, y)
        return calculate_importance(x, true) > calculate_importance(y, true)
    end)
    return cards
end

function flush(suit)
    G.hand:unhighlight_all()

    local four_fingers = next(find_joker("Four Fingers"))
    local smeared_joker = next(find_joker("Smeared Joker"))

    local cards = {}

    if smeared_joker then
        if suit == "Spades" or suit == "Clubs" then
            cards = sorted_cards_by_suit("Spades", "Clubs")
        end
        if suit == "Hearts" or suit == "Diamonds" then
            cards = sorted_cards_by_suit("Hearts", "Diamonds")
        end
    else
        cards = sorted_cards_by_suit(suit)
    end

    if #cards >= 5 then
        cards = take(cards, 5)
        select_hand(cards)
        G.FUNCS.play_cards_from_highlighted()
    elseif four_fingers and #cards >= 4 then
        cards = take(cards, 4)
        select_hand(cards)
        G.FUNCS.play_cards_from_highlighted()
    else
        cards = {}
        for i = #G.hand.cards, 1, -1 do
            card = G.hand.cards[i]
            if get_visible_suit(card) ~= suit and get_visible_suit(card) ~= "Wild" then
                table.insert(cards, card)
            end
        end
        table.sort(cards, function(x, y)
            return calculate_importance(x, false) > calculate_importance(y, false)
        end)
        cards = take(cards, 5)
        select_hand(cards)
        discard_or_play()
    end
end

-- Discard the selected cards if possible.  Otherwise play them
function discard_or_play()
    if G.GAME.current_round.discards_left > 0 then
        G.FUNCS.discard_cards_from_highlighted()
    else
        G.FUNCS.play_cards_from_highlighted()
    end
end

function tableContains(table, key)
    for k,v in pairs(table) do
      if k == key then
          return true
      end
    end
    return false
  end

-- All of the code below taken with minimal modification from
-- Agoraaa's FlushHotkeys HotKeys mod
-- https://github.com/Agoraaa/FlushHotkeys/blob/main/FlushHotkeys.lua
function get_visible_suit(card)
  if card.ability.effect == "Stone Card" then return "stone" end
  if card.ability.name == "Wild Card" and not card.debuff then return "Wild" end
  if card.facing == "back" then return "mystery" end
  return card.base.suit
end

function get_visible_rank(card)
  if card.ability.effect == "Stone Card" then return "stone" end
  if card.facing == 'back' then return "stone" end
  return card.base.id -- return card.base.id seems better
end

function calculate_importance(card, is_for_play)
  -- im putting this table for fine tuning. change the numbers if you want
  local importances = {
    play = {
      seal = {
        Gold = 50,
        Blue = -10,
        Red = 50,
        Purple = -10
      },
      edition = {
        holo = 70,
        foil = 60,
        polychrome = 75
      },
      ability = {
        Steel = -20,
        Glass = 25,
        Wild = 15,
        Bonus = 25,
        Mult = 25,
        Stone = 15,
        Lucky = 25,
        Gold = -10
      }
    },
    discard = {
      seal = {
        Gold = 50,
        Blue = -10,
        Red = 50,
        Purple = -50
      },
      edition = {
        holo = 70,
        foil = 60,
        polychrome = 75
      },
      ability = {
        Steel = 30,
        Glass = 25,
        Wild = 15,
        Bonus = 25,
        Mult = 25,
        Stone = 15,
        Lucky = 25,
        Gold = 15
      }
    }
  }
  -- we can maybe implement the joker interactions
  local res = 0
  if card.flipped then return -20 end
  if card.debuff then return -5 end
  if is_for_play then
    if card.seal then
      res = res + (importances.play.seal[card.seal] or 0)
    end
    if card.edition then
      if card.edition.holo then
        res = res + importances.play.edition.holo
      elseif card.edition.foil then
        res = res + importances.play.edition.foil
      elseif card.edition.polychrome then
        res = res + importances.play.edition.polychrome
      else
        res = res + 0
      end
    end
    if card.ability then
      local effect = string.gsub(card.ability.name, " Card", "")
      res = res + (importances.play.ability[effect] or 0)
    end
  else
    if card.seal then
      res = res + (importances.discard.seal[card.seal] or 0)
    end
    if card.edition then
      if card.edition.holo then
        res = res + importances.discard.edition.holo
      elseif card.edition.foil then
        res = res + importances.discard.edition.foil
      elseif card.edition.polychrome then
        res = res + importances.discard.edition.polychrome
      else
        res = res + 0
      end
    end
    if card.ability then
      local effect = string.gsub(card.ability.name, " Card", "")
      res = res + (importances.discard.ability[effect] or 0)
    end
  end
  base_score = card.base.id
  
  res = res + get_base_chips(card.base.id)
  return res
end

function get_base_chips(rank)
    if rank == 11 or rank == 12 or rank == 13 then
        return 10
    elseif rank == 14 then
        return 11
    end
    return rank
end

function hand_importance(hand)
  res = 0
  for k, v in pairs(hand) do
    res = res + calculate_importance(v, true)
  end
  return res
end

function merge(arr1, arr2)
  local res = {}
  for k, v in pairs(arr1) do
    table.insert(res, v)
  end
  for k, v in pairs(arr2) do
    table.insert(res, v)
  end
  return res
end

function filter(arr, f)
  local res = {}
  for i, v in pairs(arr) do
    if (f(v)) then
      table.insert(res, v)
    end
  end
  return res
end

function indexOf(arr, f)
  for key, value in ipairs(arr) do
    if f(value) then return key end
  end
  return -1
end

function take(arr, n)
  local res = {}
  for i = 1, n, 1 do
    if not arr[i] then return res end
    table.insert(res, arr[i])
  end
  return res
end

function map_f(arr, f)
  local res = {}
  for k, v in pairs(arr) do
    table.insert(res, f(v))
  end
  return res
end


----------------------------------------------
------------MOD CODE END----------------------
