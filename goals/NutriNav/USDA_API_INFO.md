# USDA FoodData Central API - Data Breakdown

## 📊 What the API Provides

### Nutrition Data Available:
- ✅ **Calories** (Energy in kcal) - Nutrient ID: 1008
- ✅ **Protein** (grams) - Nutrient ID: 1003
- ✅ **Carbohydrates** (grams) - Nutrient ID: 1005
- ✅ **Fat** (Total lipid, grams) - Nutrient ID: 1004
- ✅ **Fiber** (Dietary fiber, grams) - Nutrient ID: 1079
- ✅ **Sugar** (Total sugars, grams) - Nutrient ID: 2000
- ✅ **Serving Size** (amount and unit)
- ✅ **Brand Information** (for branded products)
- ✅ **Additional nutrients** (vitamins, minerals, etc.)

### Data Types Included:

#### 1. **Foundation Foods** ✅
- **What it is**: Minimally processed or raw foods with detailed nutrient profiles
- **Examples**: Raw apples, raw chicken breast, spinach, raw tofu, eggs
- **Best for**: Basic ingredients, whole foods, raw produce
- **Nutrition data**: Very detailed, analytical values

#### 2. **SR Legacy (Standard Reference)** ✅
- **What it is**: Older USDA datasets for generic foods (preserved for compatibility)
- **Examples**: Traditional versions of raw ingredients
- **Best for**: Common foods with established nutrition data
- **Nutrition data**: Standard reference values

#### 3. **Branded Foods** ✅
- **What it is**: Actual commercial products with brand names and label nutrients
- **Examples**: "Silk Tofu", "Chobani Greek Yogurt", "Quaker Oats", packaged snacks
- **Best for**: Store-bought products, branded items
- **Nutrition data**: From product labels (updated monthly)
- **Note**: Includes brand name in results

#### 4. **FNDDS (Food & Nutrient Database for Dietary Studies)** ✅
- **What it is**: Foods as eaten in dietary surveys (e.g., "What We Eat in America")
- **Examples**: "Cooked chicken breast", "Boiled rice", "Steamed broccoli"
- **Best for**: Foods in prepared/cooked form (as people actually eat them)
- **Nutrition data**: Representative of typical preparation methods

## 🍎 What's Included:

### ✅ Raw Foods & Ingredients
- Fruits (apple, banana, orange)
- Vegetables (spinach, broccoli, carrots)
- Proteins (chicken breast, eggs, tofu)
- Grains (rice, oats, quinoa)
- Nuts & seeds
- Dairy products

### ✅ Packaged/Branded Products
- Branded tofu products
- Packaged snacks
- Cereals
- Yogurts
- Energy bars
- And many more commercial products

### ✅ Prepared Foods (Limited)
- Some cooked/prepared versions (via FNDDS)
- Foods as typically eaten (e.g., "cooked chicken", "boiled rice")
- But NOT specific restaurant dishes

## ❌ What's NOT Included:

### ❌ Restaurant Dishes
- "Big Mac" from McDonald's
- "Chicken Tikka Masala" from a restaurant
- "Half rack ribs with sauce"
- Custom restaurant menu items

### ❌ Homemade Recipes
- "My grandma's apple pie"
- Custom mixed dishes
- User-created recipes

### ❌ Specialty Preparations
- Custom marinated items (unless standardized)
- Home-fermented foods
- Unique cooking methods not in database

## 🔍 Current Implementation

Our `FoodService` currently searches:
- ✅ Foundation Foods
- ✅ SR Legacy
- ✅ Branded Foods (just added)
- ✅ FNDDS (just added)

This gives users access to:
1. **Raw ingredients** (Foundation, SR Legacy)
2. **Branded products** (Branded Foods)
3. **Prepared/cooked versions** (FNDDS)

## 💡 Recommendations

1. **For raw ingredients**: Use Foundation Foods or SR Legacy
2. **For store-bought products**: Use Branded Foods
3. **For prepared foods**: Use FNDDS (limited selection)
4. **For restaurant dishes**: Users need to manually enter or use manual entry feature

## 📝 Serving Size Information

The API provides:
- `servingSize`: Numeric amount (e.g., 100.0)
- `servingSizeUnit`: Unit (e.g., "g", "cup", "oz")
- Some entries may have multiple serving size options

## 🎯 Best Practices

1. **Show all results** - Don't filter by data type, let users see everything
2. **Display brand name** - For branded products, show the brand
3. **Allow editing** - Let users adjust values if needed
4. **Manual entry fallback** - For restaurant dishes or custom foods, use manual entry

