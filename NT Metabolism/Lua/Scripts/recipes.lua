NTMB.Recipes = {
    breaddough={
        result="breaddough",
        station="cuttingboard",
        type="strict",
        plate=nil,
        tool=nil,
        ingredients={{id="flour",amount=0.5},{id="salt",amount=0.1},{id="yeastshroom"},{id="pot_water",amount=0.1}}
    },
    flatbread={
        result="bread",
        station="oven",
        type="turnInto+keepNutrition",
        nutritionMultiplier=1.1,
        temperature=10,
        from={"breaddough"}
    },
    rawpizza={
        result="rawpizza",
        station="cuttingboard",
        type="freeformAssorted",
        ingredientTag="pizzaTopping",
        descriptionType="showIngredients",
        descriptionIngredientHeader="toppings",
        plate="plate",
        tool=nil,
        ingredients={{id="breaddough"},{id="pot_tomatosauce",amount=0.1}}
    },
    pot_tomatosauce={
        result="pot_tomatosauce",
        station="stove",
        type="potFluid",
        temperature=10,
        from={"pot_water"},
        ingredients={{id="tomato"}}
    },
    pot_water={
        result="pot_water",
        station="stove",
        type="potFluid",
        temperature=10,
        from={"pot_tainted"}
    },
    pizza={
        result="pizza",
        station="oven",
        type="turnInto+keepNutrition",
        nutritionMultiplier=1.1,
        temperature=10,
        from={"rawpizza"}
    },
    pizzaslice={
        result="pizzaslice",
        station="cuttingboard",
        type="cutUp",
        desiredYield=8,
        tool="cleaver",
        ingredients={{id="pizza",amount=0.125}}
    },
    salt={
        result="salt",
        station="stove",
        type="turnInto",
        temperature=10,
        from={"antibloodloss1"}
    },
    friedliver1={
        result="friedliver",
        station="fryer",
        type="turnInto",
        temperature=10,
        from={"livertransplant"}
    },
    friedliver2={
        result="friedliver",
        station="fryer",
        type="turnInto",
        temperature=10,
        from={"livertransplant_q1"}
    },
    deepfriedliver={
        result="deepfriedliver",
        station="fryer",
        type="turnInto",
        temperature=100,
        from={"friedliver"}
    },
    fries={
        result="fries",
        station="fryer",
        type="turnInto+keepNutrition",
        nutritionMultiplier=1.1,
        temperature=10,
        from={"potato"}
    },
    ntrib={
        result="ntrib",
        station="cuttingboard",
        type="strict",
        plate=nil,
        tool="cleaver",
        ingredients={{id="bread"},{id="onion",amount=0.5},{id="hammerheadribs",amount=0.05},{id="pickle"}}
    },
    burger={
        result="burger",
        station="cuttingboard",
        type="freeformAssorted",
        plate=nil,
        tool=nil,
        ingredientTag="meat",
        minimumFreeformIngredients=1,
        descriptionType="showIngredients",
        nutritionMultiplier=1.2,
        weightMultiplier=0.8,
        ingredients={{id="bread"}}
    },
    veggieburger={
        result="veggieburger",
        station="cuttingboard",
        type="freeformAssorted",
        minimumFreeformIngredients=1,
        plate=nil,
        tool=nil,
        ingredientTag="saladIngredient",
        descriptionType="showIngredients",
        nutritionMultiplier=1.2,
        weightMultiplier=0.8,
        ingredients={{id="bread"}}
    },
    salad={
        result="salad",
        station="cuttingboard",
        type="freeformAssorted",
        minimumFreeformIngredients=1,
        plate="plate",
        tool=nil,
        ingredientTag="saladIngredient",
        descriptionType="showIngredients",
        nutritionMultiplier=1.2,
        weightMultiplier=0.8
    },
    
}