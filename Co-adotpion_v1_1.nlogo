extensions
  [
    csv
    matrix
    rnd
    nw
  ]

globals
 [
   setup-complete?

   ; SURVEY DATA
   person-survey-file ; survey file
   car-replacement-time-list ; list with car replacement times in survey
   opinions-PV-list ; list of opinions of PV owners in survey
   opinions-EV-list ; list of opinions of EV owners in survey
   opinions-heat-pump-list ; list of opinions of heat pump owners in survey

   ; THRESHOLD VALUES FOR ADOPTION
   ; seperate values for owners and tenants for PV solar panels and heat pumps and seperate values for different EV sizes
   threshold-PV-owner
   threshold-PV-tenant
   threshold-EV-small
   threshold-EV-medium
   threshold-EV-large
   threshold-heat-pump-owner
   threshold-heat-pump-tenant

   ; TECHNOLOGICAL CHARACTERISTICS
   ; price
   ; PV
   learning-rate-PV ; the PV learning rate is 0.04 in the standard scenario
   price-PV ; price of a PV solar panel before subsidy reduction
   price-net-PV ; price of a PV solar panel after subsidy reduction
   price-min-PV ; minimum price of a PV solar panel
   price-start-PV ; price at start of simulation, used for calculations
   ; small EV
   learning-rate-EV-small ; the learning rate for small EVs is 0.06 in the standard scenario
   price-EV-small ; price of a small EV
   price-net-EV-small ; price of a small EV
   price-min-EV-small ; minimum price of a small EV
   price-start-EV-small ; price at start of simulation, used for calculations
   ; medium EV
   learning-rate-EV-medium ; the learning rate for medium EVs is 0.02 in the standard scenario
   price-EV-medium ; price of a medium sized EV
   price-net-EV-medium ; price of a medium sized EV
   price-min-EV-medium ; minimum price of a medium sized EV
   price-start-EV-medium ; price at start of simulation, used for calculations
   ; large EV
   learning-rate-EV-large ; the learning rate for large EVs is 0.01 in the standard scenario
   price-EV-large ; price of a large EV
   price-net-EV-large ; price of a large EV
   price-min-EV-large ; minimum price of a large EV
   price-start-EV-large ; price at start of simulation, used for calculations
   ; heat pump
   learning-rate-heat-pump ; the heat pump learning rate is 0.04 in the standard scenario
   price-heat-pump ; price of a heat pump
   price-net-heat-pump ; price of a heat pump after subsidy reduction
   price-min-heat-pump ; minimum price of a heat pump
   price-start-heat-pump ; price at start of simulation, used for calculations
   ; life cycle greenhouse gas emissions
   ; PV: learning rate is 0.02 in the standard scenario
   life-cycle-ghg-PV ; life cycle greenhouse gas emissions for PV solar panels [ g / kWh ]
   life-cycle-ghg-PV-min ; minimum life cycle greenhouse gas emissions for PV solar panels [ g / kWh ]
   ; EV: learning rate is 0.01 in the standard scenario
   life-cycle-ghg-EV ; life cycle greenhouse gas emissions for EV [ g / vkm ]
   life-cycle-ghg-EV-min ; minimum life cycle greenhouse gas emissions for EV [ g / vkm ]
   ; heat pump: learning rate is 0.02 in the standard scenario
   life-cycle-ghg-heat-pump ; life cycle greenhouse gas emissions for heat pumps [ g / kWh-th ]
   life-cycle-ghg-heat-pump-min ; minimum life cycle greenhouse gas emissions for heat pumps [ g / kWh-th ]

  ; EV ranges
  ; starting ranges are 200 km, 350 km, and 500 km for small, medium, and large EVs respectively, based on https://www.tcs.ch/fr/tests-conseils/conseils/mobilite-electrique/voiture-electrique-2021.php
  ; ranges are updated linearly, the standard value is 20, based on https://www.iea.org/data-and-statistics/charts/evolution-of-average-range-of-electric-vehicles-by-powertrain-2010-2021) up to a maximum defined by us
  range-EV-small
  range-EV-medium
  range-EV-large
  range-EV-max

  ; co-adoption global variables
  co-adoption-PV-EV-heat-pump
  co-adoption-PV-EV
  co-adoption-PV-heat-pump
  co-adoption-EV-heat-pump
  co-adoption-PV
  co-adoption-EV
  co-adoption-heat-pump

  ; adoption 2030/250 variables for sensitivity analysis
  pv-adoption-2030
  ev-adoption-2030
  heat-pump-adoption-2030
  pv-adoption-2050
  ev-adoption-2050
  heat-pump-adoption-2050

  ; adoption lists, these lists keep a record for at which time step an agent adopted a technology, relevant for the output files of the experiments
  adoption-PV-id-list
  adoption-EV-id-list
  adoption-heat-pump-id-list
  adoption-home-battery-id-list

  ; economic lifetimes of heating systems
  heating-system-other-lifetime
  thermal-solar-panel-lifetime
 ]

breed [ houses house ]
breed [ persons person ]
breed [ PV-solar-panels PV-solar-panel ]
breed [ thermal-solar-panels thermal-solar-panel ]
breed [ EVs EV ]
breed [ HEVs HEV ]
breed [ ICEs ICE ]
breed [ charge-points charge-point ]
breed [ heat-pumps heat-pump ]
breed [ home-batteries home-battery ]
undirected-link-breed [ neighbours neighbour ]


persons-own
 [
   ; SURVEY DATA
   person-survey-profile
   id-number

   ; GENERAL
   my-house ; house of the person
   owner? ; true if house owner, false if tennant
   car? ; whether this person owns a car
   my-car ; the car/HEV/EV of the person
   car-size ; the size of the car, can be small, medium, or large
   car-replacement-time ; after how much time the person buys/leases a new car

   ; ADOPTION
   ICE? ; whether this person owns an internal combustion engine car
   HEV? ; whether this person owns an HEV
   EV? ; whether this person owns an EV

   ; SOCIAL NETWORK AND WORD-OF-MOUTH
   neighbours-meet-and-discuss ; how much does this person like to meet and discuss with its neighbours (scale 0-1)
   opinion-PV ; what is this persons opinion on PV systems after adopting one, it would be (1) neutral, (2) positive, (3) negative, or (4) mixed
   opinion-EV ; what is this persons opinion on EVs after adopting one, it would be (1) neutral, (2) positive, (3) negative, or (4) mixed
   opinion-heat-pump ; what is this persons opinion on heat pumps after adopting one, it would be (1) neutral, (2) positive, (3) negative, or (4) mixed
   emotion-PV ; the emotions of this person about PV, one of the adoption decision factors
   emotion-EV ; the emotions of this person about PV, one of the adoption decision factors
   emotion-heat-pump ; the emotions of this person about PV, one of the adoption decision factors

 ]

houses-own
 [
   ; GENERAL
   id-number ; ID number of house, same as person living here and owned technologies
;   house-type ; can be single family house (SFH) detached, SFH semi-detached, or MFH
;   rooftop-area ; rooftop area available for PV solar panels, determined by house type
   region ; whether the house is situated in an urban, suburban, or rural area
   historic? ; whether the house is classified as historic, and therefore not allowed to install a PV system under current Swiss regulation
   direct-light? ; whether the rooftop receives direct light during the day

   ; TECHNOLOGIES
   PV-solar-panel? ; whether this house has a PV solar panel installed
   thermal-solar-panel? ; whether this house has thermal solar panels installed
   heat-pump? ; whether this house has a heat pump
   heating-system-other? ; whether this house has a heating system other than heat pump or thermal solar panels
   heating-system-other-age ; age of heating system other than heat pump or thermal solar panels
   private-parking? ; whether this house has a private parking space available where a charge point can be installed
   home-battery? ; whether a home battery is installed

   ; ENERGY MANAGEMENT
   PV-self-sufficiency-potential-local ; PV self-sufficiency-potential can be increased by battery
  ]

PV-solar-panels-own
 [
   id-number ; id-number to link with house
 ]

thermal-solar-panels-own
 [
   id-number ; id-number to link with house
   age
 ]

ICEs-own
 [
   id-number ; id-number to link with owner
   age
   car-replacement-time
]

HEVs-own
 [
   id-number ; id-number to link with owner
   age
   car-replacement-time
]

EVs-own
 [
   id-number ; id-number to link with owner
   car-size ; small, medium or large
   EV-battery-capacity ; depends on range at moment of adoption
   car-replacement-time
 ]

charge-points-own
 [
   id-number ; id-number to link with house
 ]

heat-pumps-own
 [
   id-number ; id-number to link with house
 ]

home-batteries-own
 [
   id-number ; id-number to link with house
 ]

patches-own [ ]

; INITIALIZATION FUNCTIONS

to setup
  clear-all
  set setup-complete? false ; the set-up starts

  ; load data
  set-current-directory (word "..")
  set person-survey-file csv:from-file "data/surveyData.csv"

  ; We make some seperate lists from the data because we need them later
  set car-replacement-time-list [ ]
  foreach range 1470 [ x -> set car-replacement-time-list lput item 19 item x person-survey-file car-replacement-time-list ]
  set car-replacement-time-list remove "CarPurchaseFrequency" car-replacement-time-list
  set car-replacement-time-list remove " " car-replacement-time-list

  set opinions-PV-list [ ]
  foreach range 1470 [ x -> set opinions-PV-list lput item 22 item x person-survey-file opinions-PV-list ]
  set opinions-PV-list remove "PVWoMowners" opinions-PV-list
  set opinions-PV-list remove " " opinions-PV-list

  set opinions-EV-list [ ]
  foreach range 1470 [ x -> set opinions-EV-list lput item 22 item x person-survey-file opinions-EV-list ]
  set opinions-EV-list remove "EVWoMowners" opinions-EV-list
  set opinions-EV-list remove " " opinions-EV-list

  set opinions-heat-pump-list [ ]
  foreach range 1470 [ x -> set opinions-heat-pump-list lput item 22 item x person-survey-file opinions-heat-pump-list ]
  set opinions-heat-pump-list remove "HPWoMowners" opinions-heat-pump-list
  set opinions-heat-pump-list remove " " opinions-heat-pump-list

  ; create empty lists for keeping records of which persons adopt a technology when
  set adoption-PV-id-list []
  set adoption-EV-id-list []
  set adoption-heat-pump-id-list []
  set adoption-home-battery-id-list []

  ; Rural areas are coloured green, suburban areas are coloured brown, urban areas are coloured light gray
  ; The number of patches defined as urban, suburban, and rural are set in a way that the density of persons corresponds to that of the density of dwellings in urban, suburban, and rural regions in Suisse Romande respectively
  ask patches [ set pcolor green ]
  ask patches with [ distance patch 0 0 <= 31 ] [ set pcolor gray + 2 ]
  ask patches with [ distance patch 0 0 <= 18 ] [ set pcolor gray ]

  ; set learning rates and prices
  set learning-rate-PV 0.04 ; learning rate in standard scenario
  set price-min-PV 5000 ; minimum price for a standard solar panels
  set price-start-PV 15000 ; used for calculations
  set price-PV price-start-PV  ; used for calculations
  set price-net-PV price-PV * ( 1 - subsidy-PV / 100 )

  set learning-rate-EV-small 0.15 ; learning rate in standard scenario
  set price-min-EV-small 8000 ; minimum price for a small EV
  set price-start-EV-small 18000 ; used for calculations
  set price-EV-small price-start-EV-small ; used for calculations
  set price-net-EV-small price-EV-small * ( 1 - subsidy-EV / 100 )

  set learning-rate-EV-medium 0.15 ; learning rate in standard scenario
  set price-min-EV-medium 29000 ; minimum price for a medium sized EV
  set price-start-EV-medium 44000 ; used for calculations
  set price-EV-medium price-start-EV-medium ; used for calculations
  set price-net-EV-medium price-EV-medium * ( 1 - subsidy-EV / 100 )

  set learning-rate-EV-large 0.15 ; learning rate in standard scenario
  set price-min-EV-large 80000 ; minimum price for a small EV
  set price-start-EV-large 100000 ; used for calculations
  set price-EV-large price-start-EV-large ; used for calculations
  set price-net-EV-large price-EV-large * ( 1 - subsidy-EV / 100 )

  set learning-rate-heat-pump 0.04 ; learning rate in standard scenario
  set price-min-heat-pump 5000 ; minimum price for a heat pump
  set price-start-heat-pump 15800 ; used for calculations
  set price-heat-pump price-start-heat-pump ; used for calculations
  set price-net-heat-pump price-heat-pump * ( 1 - subsidy-heat-pump / 100 )

  ; EV savings are set
  if savings-EV = "low" [
    set savings-EV-small 3.3
      set savings-EV-medium 3.7
      set savings-EV-large 4.1
  ]

  if savings-EV = "medium" [
    set savings-EV-small 5.3
    set savings-EV-medium 7.1
    set savings-EV-large 10.5
  ]

  if savings-EV = "high" [
    set savings-EV-small 8.4
    set savings-EV-medium 10.5
    set savings-EV-large 12.6
  ]

  ; set life cycle greenhouse gas emissions
  set life-cycle-ghg-PV 80 ; life cycle greenhouse gas emissions for PV solar panels [ g / kWh ]
  set life-cycle-ghg-PV-min 40 ; minimum life cycle greenhouse gas emissions for PV solar panels [ g / kWh ]
  set life-cycle-ghg-EV 80 ; life cycle greenhouse gas emissions for EV [ g / vkm ]
  set life-cycle-ghg-EV-min 60 ; minimum life cycle greenhouse gas emissions for EV [ g / vkm ]
  set life-cycle-ghg-heat-pump 50 ; life cycle greenhouse gas emissions for heat pumps [ g / kWh-th ]
  set life-cycle-ghg-heat-pump-min 30 ; minimum life cycle greenhouse gas emissions for heat pumps [ g / kWh-th ]

  ; set beginning and max values EV ranges
  set range-EV-small 200
  set range-EV-medium 350
  set range-EV-large  500
  set range-EV-max 700

  ; economic lifetimes of heating systems
  set heating-system-other-lifetime 25
  set thermal-solar-panel-lifetime 25
  if not replacement-time? [
    set heating-system-other-lifetime 1
    set thermal-solar-panel-lifetime 1
  ]


  ; threshold values, estimated based on survey data
  set threshold-PV-owner 0.5
  set threshold-PV-tenant 0.45
  set threshold-EV-small 0.45
  set threshold-EV-medium 0.40
  set threshold-EV-large 0.95
  set threshold-heat-pump-owner 0.5
  set threshold-heat-pump-tenant 0.45

  ; SENSITIVITY ANALYSIS
  ; in the sensitivity analysis we can test the impact of variations in certain variables on the model outcomes
  if sensitivity-analysis? [
    set learning-rate-PV learning-rate-PV * ( sensitivity-learning-rate-PV / 100 )
    set learning-rate-EV-small learning-rate-EV-small * ( sensitivity-learning-rate-EV / 100 )
    set learning-rate-EV-medium learning-rate-EV-medium * ( sensitivity-learning-rate-EV / 100 )
    set learning-rate-EV-large learning-rate-EV-large * ( sensitivity-learning-rate-EV / 100 )
    set learning-rate-heat-pump learning-rate-heat-pump * ( sensitivity-learning-rate-heat-pump / 100 )
    set price-min-PV price-min-PV * ( sensitivity-price-min-PV / 100 )
    set price-min-EV-small price-min-EV-small * ( sensitivity-price-min-EV / 100 )
    set price-min-EV-medium price-min-EV-medium * ( sensitivity-price-min-EV / 100 )
    set price-min-EV-large price-min-EV-large * ( sensitivity-price-min-EV / 100 )
    set price-min-heat-pump price-min-heat-pump * ( sensitivity-price-min-heat-pump / 100 )
    set subsidy-PV subsidy-PV * ( sensitivity-subsidy-PV / 100 )
    set subsidy-EV subsidy-EV * ( sensitivity-subsidy-EV / 100 )
    set subsidy-heat-pump subsidy-heat-pump * ( sensitivity-subsidy-heat-pump / 100 )
    set bundle-bonus bundle-bonus * ( sensitivity-bundle-bonus / 100 )
    set PV-net-bill-after-adoption ifelse-value ( PV-net-bill-after-adoption > 0 )
           [ PV-net-bill-after-adoption * ( sensitivity-PV-net-bill-after-adoption / 100 ) ]
           [ PV-net-bill-after-adoption * ( 2 - sensitivity-PV-net-bill-after-adoption / 100 ) ]
    set savings-EV-small savings-EV-small * ( sensitivity-savings-EV / 100 )
    set savings-EV-medium savings-EV-medium * ( sensitivity-savings-EV / 100 )
    set savings-EV-large savings-EV-large * ( sensitivity-savings-EV / 100 )
    set savings-heat-pump savings-heat-pump * ( sensitivity-savings-heat-pump / 100 )
    set learning-rate-life-cycle-ghg-PV learning-rate-life-cycle-ghg-PV  * ( sensitivity-learning-rate-ghg-PV / 100 )
    set learning-rate-life-cycle-ghg-EV learning-rate-life-cycle-ghg-EV  * ( sensitivity-learning-rate-ghg-EV / 100 )
    set learning-rate-life-cycle-ghg-heat-pump learning-rate-life-cycle-ghg-heat-pump  * ( sensitivity-learning-rate-ghg-heat-pump / 100 )
    set life-cycle-ghg-PV-min life-cycle-ghg-PV-min * ( sensitivity-min-ghg-PV / 100 )
    set life-cycle-ghg-EV-min life-cycle-ghg-EV-min * ( sensitivity-min-ghg-EV / 100 )
    set life-cycle-ghg-heat-pump-min life-cycle-ghg-heat-pump-min * ( sensitivity-min-ghg-heat-pump / 100 )
    set number-of-neighbours round ( number-of-neighbours * ( sensitivity-number-of-neighbours / 100 ) )
    set PV-self-sufficiency-potential-global PV-self-sufficiency-potential-global * ( sensitivity-PV-self-sufficiency-potential / 100 )
    set range-EV-increase range-EV-increase * ( sensitivity-range-EV-increase / 100 )
    set range-EV-max range-EV-max * ( sensitivity-range-EV-max / 100 )
    set heating-system-other-lifetime heating-system-other-lifetime * ( sensitivity-replacement-time-heating-system / 100 )
    set thermal-solar-panel-lifetime thermal-solar-panel-lifetime * ( sensitivity-replacement-time-heating-system / 100 )
  ]

  ; create houses
  create-houses households
    [
      set shape "house"
      set color gray
      set PV-self-sufficiency-potential-local PV-self-sufficiency-potential-global
      set PV-solar-panel? false
      set heat-pump? false
      set heating-system-other? false
      set thermal-solar-panel? false
      set home-battery? false
      ]

  ; create persons that live in a house
  ask houses [
      let house-id who
      hatch-persons 1 [
        set my-house myself ; house-id ; number that keeps track of which house a persons lives in
        set shape "person"
        set color white
        choose-person-profile
        ask house house-id [ set id-number [ id-number ] of myself ]
        set ICE? false
        set HEV? false
        set EV? false
        initialize-person-profile
      ]
     ]

  ; social networks consist of neighbours, which are defined as the persons closest to oneself
  ask persons [ create-neighbours-with min-n-of number-of-neighbours other persons [ distance myself ] ]

  ; update global co-adoption indicators
  set co-adoption-PV-EV-heat-pump count persons with [ [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and EV? ]
  set co-adoption-PV-EV  count persons with [ [ PV-solar-panel? ] of my-house and not [ heat-pump? ] of my-house and EV? ]
  set co-adoption-PV-heat-pump count persons with [ [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and not EV? ]
  set co-adoption-EV-heat-pump count persons with [ not [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and EV? ]
  set co-adoption-PV count persons with [ [ PV-solar-panel? ] of my-house and not [ heat-pump? ] of my-house and not EV? ]
  set co-adoption-EV count persons with [ not [ PV-solar-panel? ] of my-house and not [ heat-pump? ] of my-house and EV? ]
  set co-adoption-heat-pump count persons with [ not [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and not EV? ]

  set setup-complete? true ; the set-up is now completed
  reset-ticks

end

to choose-person-profile
  ; choose random survey variables and betas from file, and make sure that every person has unique profiles
  let a random ( length person-survey-file - 1) + 1
    set person-survey-profile item a person-survey-file
    set person-survey-file remove-item a person-survey-file
  ; the person's ID number is the same as the respondent number
  set id-number item 0 person-survey-profile

end

to initialize-person-profile

  ; persons are owners or tennants of their houses
  ifelse item 1 person-survey-profile = 1 [ set owner? true ] [ set owner? false ]

  if item 2 person-survey-profile = "urban" [ move-to one-of patches with [ not any? persons-here and pcolor = gray ] ]
  if item 2 person-survey-profile = "suburban" [ move-to one-of patches with [ not any? persons-here and pcolor = gray + 2 ] ]
  if item 2 person-survey-profile = "rural" [ move-to one-of patches with [ not any? persons-here and pcolor = green ] ]
  ask my-house [ move-to myself ]

  ; house characteristics
  ifelse item 3 person-survey-profile = "Yes"
    [ ask my-house [ set historic? true ] ]
    [ ask my-house [ set historic? false ] ]
  ifelse item 4 person-survey-profile = "Yes"
    [ ask my-house [ set direct-light? true ] ]
    [ ask my-house [ set direct-light? false ] ]
  ifelse item 6 person-survey-profile = "Yes"
    [ ask my-house [ set private-parking? true ] ]
    [ ask my-house [ set private-parking? false ] ]

  ; persons with a car or with future plans to buy a car
  ifelse item 7 person-survey-profile = 1 OR item 8 person-survey-profile = 1 OR item 9 person-survey-profile = 1 OR item 14 person-survey-profile = "YES" [ set car? true ] [ set car? false ]
  set car-size item 25 person-survey-profile ; they have a small, medium, or large car
  ; and replace their car after a certain number of years
  if item 19 person-survey-profile = "every 12 years or when needed" [ set car-replacement-time 12 ]
  if item 19 person-survey-profile = "every 8 years" [ set car-replacement-time 8 ]
  if item 19 person-survey-profile = "every 4 years" [ set car-replacement-time 4 ]
  if item 19 person-survey-profile = "every year" [ set car-replacement-time 1 ]
  ; persons that indicated they will buy a car in the future choose their replacement time from the distribution of replacement times given by respondents that own a car
  if item 19 person-survey-profile = " " [
    let car-replacement-time-temporary one-of car-replacement-time-list
    if car-replacement-time-temporary = "every 12 years or when needed" [ set car-replacement-time 12 ]
    if car-replacement-time-temporary = "every 8 years" [ set car-replacement-time 8 ]
    if car-replacement-time-temporary = "every 4 years" [ set car-replacement-time 4 ]
    if car-replacement-time-temporary = "every year" [ set car-replacement-time 1 ]
    ]
  if not replacement-time? [ set car-replacement-time 1 ]

  ; At the start of the simulation, some persons already have adopted an ICE car, HEV, EV PV solar panels, thermal solar panels, heat pump, or home battery
  ; ICE cars
  if item 7 person-survey-profile = 1 and item 18 person-survey-profile = "ConventionalCAR"
    [ adopt-ICE
      ifelse item 15 person-survey-profile = "Je ne me souviens pas"
        [ ask my-car [ set age random [ car-replacement-time ] of myself ] ] ; we set a random age if the respondent forgot the year of adoption
        [ ask my-car [ set age 2022 - [ item 15 person-survey-profile ] of myself ] ] ] ; otherwise we set the age based on survey data


  ; HEVs
  if item 8 person-survey-profile = 1 and item 18 person-survey-profile = "HEV"
    [ adopt-HEV
      ifelse item 16 person-survey-profile = "Je ne me souviens pas"
        [ ask my-car [ set age random [ car-replacement-time ] of myself ] ] ; we set a random age if the respondent forgot the year of adoption
        [ ask my-car [ set age 2022 - [ item 16 person-survey-profile ] of myself ] ] ]; otherwise we set the age based on survey data

  ; EVs
  if item 9 person-survey-profile = 1 and item 18 person-survey-profile = "EV"
    [
      adopt-EV
      ; from owners in the survey we know their opinion on the technology
      ifelse extreme-scenario-testing? [ ; opinions are set in extreme scenario testing
        set opinion-EV extreme-scenarios-opinions
      ]
      [
        set opinion-EV item 17 person-survey-profile
      ]
    ]

  ; PV solar panels
  if item 10 person-survey-profile = 1
    [
      adopt-PV-solar-panel
      ; from owners in the survey we know their opinion on the technology
      ifelse extreme-scenario-testing? [ ; opinions are set in extreme scenario testing
        set opinion-PV extreme-scenarios-opinions
      ]
      [
        set opinion-PV item 22 person-survey-profile
      ]
    ]

  ; Thermal solar panels
  if item 11 person-survey-profile = 1
    [ adopt-thermal-solar-panel
      ifelse item 20 person-survey-profile = "Je ne me souviens pas"
        [ ask thermal-solar-panels with [ id-number = [ id-number ] of myself ] [ set age random thermal-solar-panel-lifetime ] ] ; we set a random age if the respondent forgot the year of adoption
        [ ask thermal-solar-panels with [ id-number = [ id-number ] of myself ] [ set age 2022 - [ item 20 person-survey-profile ] of myself ] ] ; otherwise we set the age based on survey data
    ]

  ; Heat pumps
  if item 12 person-survey-profile = 1
    [
      adopt-heat-pump
      ; from owners in the survey we know their opinion on the technology
      ifelse extreme-scenario-testing? [ ; opinions are set in extreme scenario testing
        set opinion-EV extreme-scenarios-opinions
      ]
      [
        set opinion-heat-pump item 21 person-survey-profile
      ]
    ]

  ; Other heating systems
  ask my-house [ if not thermal-solar-panel? and not heat-pump? [
    set heating-system-other? true
    if item 5 [ person-survey-profile ] of myself = "I don't know" [ set heating-system-other-age random heating-system-other-lifetime ]
    if item 5 [ person-survey-profile ] of myself = "2019 or later" [ set heating-system-other-age random 1 + 1 ]
    if item 5 [ person-survey-profile ] of myself = "2010-2019" [ set heating-system-other-age random 10 + 3 ]
    if item 5 [ person-survey-profile ] of myself = "1990-1999" [ set heating-system-other-age random 10 + 13 ]
    if item 5 [ person-survey-profile ] of myself = "1980-1989" [ set heating-system-other-age random heating-system-other-lifetime ] ; 10 + 23 ]
    if item 5 [ person-survey-profile ] of myself = "1970-1979" [ set heating-system-other-age random heating-system-other-lifetime ] ; 10 + 33 ]
    if item 5 [ person-survey-profile ] of myself = "1960-1969" [ set heating-system-other-age random heating-system-other-lifetime ] ; 10 + 43 ]
    if item 5 [ person-survey-profile ] of myself = "Before 1960" [ set heating-system-other-age random heating-system-other-lifetime ] ; ]
    ]
  ]

  ; Home batteries
  if item 13 person-survey-profile = 1 OR item 23 person-survey-profile = "Yes" [
    adopt-home-battery
     ask my-house [
      set PV-self-sufficiency-potential-local min list 1 ( PV-self-sufficiency-potential-global + 0.4 )
    ]
  ]

  ; persons have an emotion about the technologies
  set emotion-PV item 46 person-survey-profile
  set emotion-EV item 47 person-survey-profile
  set emotion-heat-pump item 46 person-survey-profile

  ; persons have a certain fondness to meet and discuss with their neighbours, which is captured in the following variable (scale 0-1)
  ; this value can be increase by the policy stimulating social interaction
  ifelse extreme-scenario-testing? [ ; neighbours-mmeet-and-discuss values are set in extreme scenario testing
      set neighbours-meet-and-discuss extreme-scenario-neighbours-meet-and-discuss
    ]
    [
      set neighbours-meet-and-discuss min list ( ( item 26 person-survey-profile - 1 ) / 6 + stimulate-social-interaction ) 1
    ]

  ; in extreme scenario testing, the savings are set:
  if extreme-scenario-testing? [
    ifelse extreme-scenario-savings = "low" [
      set PV-net-bill-after-adoption -483.5
      set savings-EV-small 3.3
      set savings-EV-medium 3.7
      set savings-EV-large 4.1
      set savings-heat-pump 2200
    ]
    [
      set PV-net-bill-after-adoption 90
      set savings-EV-small 8.4
      set savings-EV-medium 10.5
      set savings-EV-large 12.5
      set savings-heat-pump 2800
    ]
  ; and whether there will be an information campaing
    ifelse extreme-scenario-information-campaign? [
      set information-campaign-PV-year 2022
      set information-campaign-EV-year 2022
      set information-campaign-heat-pump-year 2022
    ]
    [
      set information-campaign-PV-year 2051
      set information-campaign-EV-year 2051
      set information-campaign-heat-pump-year 2051
    ]
  ]

end

; RUN SIMULATION

to go
  ; UPDATES-START
  ; reset the lists for keeping records of which persons adopt a technology when
  set adoption-PV-id-list []
  set adoption-EV-id-list []
  set adoption-heat-pump-id-list []
  set adoption-home-battery-id-list []

  ; keep track of adoption in 2030
  if ticks = 9 [
    ; keep track of adoption levels 2030 for sensitivity analysis
    set pv-adoption-2030 count PV-solar-panels
    set ev-adoption-2030 count EVs
    set heat-pump-adoption-2030 count heat-pumps

    print ( word "2030: PV solar panels: " count PV-solar-panels "   EVs: " count EVs "   Heat pumps: " count heat-pumps "   co-adoption PV-EV-heat pump: " co-adoption-PV-EV-heat-pump
   "   co-adoption PV-EV: " co-adoption-PV-EV "   co-adoption PV-heat pump: " co-adoption-PV-heat-pump "   co-adoption EV-heat pump: " co-adoption-EV-heat-pump )
  ]
  ; and 2050
  if ticks = 29 [
    ; keep track of adoption levels 2030 for sensitivity analysis
    set pv-adoption-2050 count PV-solar-panels
    set ev-adoption-2050 count EVs
    set heat-pump-adoption-2050 count heat-pumps

    print ( word "2050: PV solar panels: " count PV-solar-panels "   EVs: " count EVs "   Heat pumps: " count heat-pumps "   co-adoption PV-EV-heat pump: " co-adoption-PV-EV-heat-pump
   "   co-adoption PV-EV: " co-adoption-PV-EV "   co-adoption PV-heat pump: " co-adoption-PV-heat-pump "   co-adoption EV-heat pump: " co-adoption-EV-heat-pump )
  ]

  ; update technological attributes; prices and life cycle ghg emissions
  ; to let persons update their subjective probability
  ; prices
  ifelse extreme-scenario-testing? [ ; in extreme scenario testing prices are fixed
    ifelse extreme-scenario-prices = "low" [
      set price-net-PV 5000
      set price-net-EV-small 8000
      set price-net-EV-medium 29000
      set price-net-EV-large 80000
      set price-net-heat-pump 5000
    ]
    [
      set price-net-PV 15000
      set price-net-EV-small 18000
      set price-net-EV-medium 44000
      set price-net-EV-large 100000
      set price-net-heat-pump 15000
    ]
  ]
  [
    let price-PV-previous price-PV
    set price-PV max list ( price-PV * ( 1 - learning-rate-PV ) ) price-min-PV
    set price-net-PV price-PV * ( 1 - subsidy-PV / 100 )

    let price-EV-small-previous price-EV-small
    set price-EV-small max list ( price-EV-small * ( 1 - learning-rate-EV-small ) ) price-min-EV-small
    set price-net-EV-small price-EV-small * ( 1 - subsidy-EV / 100 )

    let price-EV-medium-previous price-EV-medium
    set price-EV-medium max list ( price-EV-medium * ( 1 - learning-rate-EV-medium ) ) price-min-EV-medium
    set price-net-EV-medium price-EV-medium * ( 1 - subsidy-EV / 100 )

    let price-EV-large-previous price-EV-large
    set price-EV-large max list ( price-EV-large * ( 1 - learning-rate-EV-large ) ) price-min-EV-large
    set price-net-EV-large price-EV-large * ( 1 - subsidy-EV / 100 )

    let price-heat-pump-previous price-heat-pump
    set price-heat-pump max list ( price-heat-pump * ( 1 - learning-rate-heat-pump ) ) price-min-heat-pump
    set price-net-heat-pump price-heat-pump * ( 1 - subsidy-heat-pump / 100 )
  ]

  ; update life cycle GHG emissions
  ifelse extreme-scenario-testing? [ ; in extreme scenario testing GHG emissions are fixed
    ifelse extreme-scenario-GHG = "low" [
      set life-cycle-ghg-PV 40
      set life-cycle-ghg-EV 60
      set life-cycle-ghg-heat-pump 30
    ]
    [
      set life-cycle-ghg-PV 80
      set life-cycle-ghg-EV 80
      set life-cycle-ghg-heat-pump 50
    ]
  ]
  [
    let life-cycle-ghg-PV-previous life-cycle-ghg-PV
    set life-cycle-ghg-PV max list ( life-cycle-ghg-PV * ( 1 - learning-rate-life-cycle-ghg-PV ) ) life-cycle-ghg-PV-min
    let life-cycle-ghg-EV-previous life-cycle-ghg-EV
    set life-cycle-ghg-EV max list ( life-cycle-ghg-EV * ( 1 - learning-rate-life-cycle-ghg-EV ) ) life-cycle-ghg-EV-min
    let life-cycle-ghg-heat-pump-previous life-cycle-ghg-heat-pump
    set life-cycle-ghg-heat-pump max list ( life-cycle-ghg-heat-pump * ( 1 - learning-rate-life-cycle-ghg-heat-pump ) ) life-cycle-ghg-heat-pump-min
  ]

  ; update EV ranges
  ifelse extreme-scenario-testing? [ ; in extreme scenario EV ranges are fixed
    set range-EV-small extreme-scenario-EV-range
    set range-EV-medium extreme-scenario-EV-range
    set range-EV-large extreme-scenario-EV-range
  ] [
    set range-EV-small min list ( range-EV-small + range-EV-increase ) range-EV-max
    set range-EV-medium min list ( range-EV-medium + range-EV-increase ) range-EV-max
    set range-EV-large min list ( range-EV-large + range-EV-increase ) range-EV-max
  ]

  ; update age of technologies that can be replaced
  ask thermal-solar-panels [
    set age age + 1
    if age >= thermal-solar-panel-lifetime [
      ask houses with [ id-number = [ id-number ] of myself ] [ set thermal-solar-panel? false ]
      die
      ]
    ]
  ask ICEs [
    set age age + 1
    if age >= car-replacement-time [
      ask persons with [ id-number = [ id-number ] of myself ] [ set ICE? false ]
      die
      ]
    ]
  ask HEVs [
    set age age + 1
    if age >= car-replacement-time [
      ask persons with [ id-number = [ id-number ] of myself ] [ set HEV? false ]
      die
      ]
    ]

  ask houses with [ heating-system-other? ] [
    set heating-system-other-age heating-system-other-age + 1
    if heating-system-other-age >= heating-system-other-lifetime [ set heating-system-other? false ]
    ]

  ; INFORMATION CAMPAIGNS
  ; influence the emotions of persons
  if ticks = information-campaign-PV-year - 2022 [
    ask persons [ set emotion-PV min list ( max list ( emotion-PV + item 131 person-survey-profile ) 0 ) 1 ]
  ]
  if ticks = information-campaign-EV-year - 2022 [
    ask persons [ set emotion-EV min list ( max list ( emotion-EV + item 135 person-survey-profile ) 0 ) 1 ]
  ]
  if ticks = information-campaign-heat-pump-year - 2022 [
    ask persons [ set emotion-heat-pump min list ( max list ( emotion-heat-pump + item 133 person-survey-profile ) 0 ) 1 ]
  ]

  ; STIMULATING SOCIAL INTERACTIONS
  ; Value is updated in case of any chances
  ask persons [
  ifelse extreme-scenario-testing? [ ; neighbours-meet-and-discuss values are set in extreme scenario testing
      set neighbours-meet-and-discuss extreme-scenario-neighbours-meet-and-discuss
    ]
    [
      set neighbours-meet-and-discuss min list ( ( item 26 person-survey-profile - 1 ) / 6 + stimulate-social-interaction ) 1
    ]
  ]

  ; ADOPTION DECISIONS
  ; BUNDLE
  ; If there is a bundle bonus, persons will first consider buying bundles of technologies
  if bundle-bonus > 0 [
    ; PV/EV/heat pump bundle
    ask persons with [
      ; PV/heat pump barriers
      ( owner? OR tenants-can-install ) and
      ( not [ historic? ] of my-house OR historic-houses-can-install-PV ) and
      [ direct-light? ] of my-house and
      not [ PV-solar-panel? ] of my-house and
      not [ thermal-solar-panel? ] of my-house and
      ; EV requirements
      car? and not ICE? and not HEV? and not EV? and
      ; heat pump barriers
      not [ heating-system-other? ] of my-house and
      not [ thermal-solar-panel? ] of my-house and
      not [ heat-pump? ] of my-house and
      ; evaluation of bundles
      evaluate-PV-solar-panel-bundle and
      evaluate-heat-pump-bundle and
      ( ( ifelse-value car-size = "Small car" [ evaluate-EV-small-bundle ] [ false ] ) OR
        ( ifelse-value car-size = "Medium car" [ evaluate-EV-medium-bundle ] [ false ] ) OR
        ( ifelse-value car-size = "Large car" [ evaluate-EV-large-bundle ] [ false ] )
      )
      ]
      [
        adopt-PV-solar-panel
        adopt-EV
        adopt-heat-pump
      ]
  ]
  if bundle-bonus > 0 [
    ; PV/EV bundle
    ask persons with [
      ; PV barriers
      ( owner? OR tenants-can-install ) and
      ( not [ historic? ] of my-house OR historic-houses-can-install-PV ) and
      [ direct-light? ] of my-house and
      not [ PV-solar-panel? ] of my-house and
      not [ thermal-solar-panel? ] of my-house and
      ; EV requirements
      car? and not ICE? and not HEV? and not EV? and
      ; evaluation of bundles
      evaluate-PV-solar-panel-bundle and
      ( ( ifelse-value car-size = "Small car" [ evaluate-EV-small-bundle ] [ false ] ) OR
        ( ifelse-value car-size = "Medium car" [ evaluate-EV-medium-bundle ] [ false ] ) OR
        ( ifelse-value car-size = "Large car" [ evaluate-EV-large-bundle ] [ false ] )
      )
      ]
      [
        adopt-PV-solar-panel
        adopt-EV
      ]
    ]
  if bundle-bonus > 0 [
    ; EV/heat pump bundle
    ask persons with [
      ; EV requirements
      car? and not ICE? and not HEV? and not EV? and
      ; heat pump barriers
      ( owner? OR tenants-can-install ) and
      not [ heating-system-other? ] of my-house and
      not [ thermal-solar-panel? ] of my-house and
      not [ heat-pump? ] of my-house and
      ; evaluation of bundles
      evaluate-heat-pump-bundle and
      ( ( ifelse-value car-size = "Small car" [ evaluate-EV-small-bundle ] [ false ] ) OR
        ( ifelse-value car-size = "Medium car" [ evaluate-EV-medium-bundle ] [ false ] ) OR
        ( ifelse-value car-size = "Large car" [ evaluate-EV-large-bundle ] [ false ] )
      )
      ]
      [
        adopt-EV
        adopt-heat-pump
      ]
  ]

  ; persons without any barriers evaluate whether they buy PV
  ask persons with [
    ( owner? OR tenants-can-install ) and
    ( not [ historic? ] of my-house OR historic-houses-can-install-PV ) and
    [ direct-light? ] of my-house and
    not [ PV-solar-panel? ] of my-house and
    not [ thermal-solar-panel? ] of my-house  ]
      [ evaluate-PV-solar-panel ]

  ; persons whose heating system is a the end of its lifetime and who don't have any barriers consider adopting a heat pump
  ask persons with [
    ( owner? OR tenants-can-install ) and
    not [ heating-system-other? ] of my-house and
    not [ thermal-solar-panel? ] of my-house and
    not [ heat-pump? ] of my-house ]
      [ evaluate-heat-pump ]

  ; persons without any heating system adopt "heating system other"
  ask persons with [
    not [ heating-system-other? ] of my-house and
    not [ thermal-solar-panel? ] of my-house and
    not [ heat-pump? ] of my-house ]
      [ ask my-house [
          set heating-system-other? true
          set heating-system-other-age 0
          ]
      ]

  ; persons that drive a car but the previous one is at the end of its lifetime may buy an EV in different sizes depending on their car size
  ask persons with [ car? and not ICE? and not HEV? and not EV? and car-size = "Small car" ] [ evaluate-EV-small ]
  ask persons with [ car? and not ICE? and not HEV? and not EV? and car-size = "Medium car" ] [ evaluate-EV-medium ]
  ask persons with [ car? and not ICE? and not HEV? and not EV? and car-size = "Large car" ] [ evaluate-EV-large ]

  ; UPDATES-END
  ; update global co-adoption indicators
  set co-adoption-PV-EV-heat-pump count persons with [ [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and EV? ]
  set co-adoption-PV-EV  count persons with [ [ PV-solar-panel? ] of my-house and not [ heat-pump? ] of my-house and EV? ]
  set co-adoption-PV-heat-pump count persons with [ [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and not EV? ]
  set co-adoption-EV-heat-pump count persons with [ not [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and EV? ]
  set co-adoption-PV count persons with [ [ PV-solar-panel? ] of my-house and not [ heat-pump? ] of my-house and not EV? ]
  set co-adoption-EV count persons with [ not [ PV-solar-panel? ] of my-house and not [ heat-pump? ] of my-house and EV? ]
  set co-adoption-heat-pump count persons with [ not [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and not EV? ]



  tick

  if ticks = stop-after-x-years + 1 [ stop ]

end

; ADOPTION FUNCTIONS

to adopt-PV-solar-panel
  if [ PV-solar-panel? ] of my-house = false [
  ask my-house [
    set PV-solar-panel? true
    hatch-PV-solar-panels 1 [
      set shape "sun"
      set color yellow
      set size 0.5
      set heading 315
      forward 0.4
      set id-number [ id-number ] of myself
    ]
  ]

  ; persons that adopt after the initialisation randomly choose an opinion from the distribution results from the survey
  ifelse extreme-scenario-testing? [ ; opinions are set in extreme scenario testing
      set opinion-PV extreme-scenarios-opinions
    ]
    [
      set opinion-PV one-of opinions-PV-list
    ]
  ; they send out new comments to their neighbours about the technologies
  ; depending on how much they discuss with their neighbours (variable neighbours-meet-and-discuss)
  ; and how old their technology is
  ; this influences the emotions of their neighbours about the relevant technologies
  if word-of-mouth? [
    ; positive comments
    if opinion-PV = "PositiveFeedback" or opinion-PV = "MixedFeedback" [
      ask n-of ( round neighbours-meet-and-discuss * number-of-neighbours ) link-neighbors [
        set emotion-PV min list ( max list ( emotion-PV + item 131 person-survey-profile ) 0 ) 1 ]
      ]
    ; negative comments
    if opinion-PV = "NegativeFeedback" or opinion-PV = "MixedFeedback" [
      ask n-of ( round neighbours-meet-and-discuss * number-of-neighbours ) link-neighbors [
        set emotion-PV min list ( max list ( emotion-PV + item 132 person-survey-profile ) 0 ) 1 ]
      ]
   ]

  ; a certain number of PV adoptors also adopts a battery, based on their answer in the survey
  if  item 24 person-survey-profile = "Yes" [ adopt-home-battery ]

  ; update the list for keeping records of which persons adopt PV when
  set adoption-PV-id-list lput id-number adoption-PV-id-list
  ]
end

to adopt-thermal-solar-panel
  ask my-house [
    set thermal-solar-panel? true
    set heating-system-other? false
    hatch-thermal-solar-panels 1 [
      set shape "sun"
      set color orange
      set size 0.5
      set heading 135
      forward 0.4
      set id-number [ id-number ] of myself
      set age 0
    ]
  ]
end

to adopt-ICE
  set ICE? true
  hatch-ICEs 1 [
    set shape "car"
    set color gray - 2
    set size 0.5
    set heading 95
    forward 0.2
    set id-number [ id-number ] of myself
    set car-replacement-time [ car-replacement-time ] of myself
    set age 0
  ]
  set my-car ICEs with [ id-number = [ id-number ] of myself ]
end

to adopt-HEV
  set HEV? true
  hatch-HEVs 1 [
    set shape "car"
    set color gray + 2
    set size 0.5
    set heading 90
    forward 0.2
    set id-number [ id-number ] of myself
    set car-replacement-time [ car-replacement-time ] of myself
    set age 0
  ]
  set my-car HEVs with [ id-number = [ id-number ] of myself ]
end

to adopt-EV
  if EV? = false [
  set EV? true
  hatch-EVs 1 [
    set shape "car"
    set color green
    set size 0.5
    set heading 90
    forward 0.25
    set id-number [ id-number ] of myself
    set car-size [ car-size ] of myself
  ]
  set my-car EVs with [ id-number = [ id-number ] of myself ]

  ; EV owners with the ability to install a home charge point will do so
  ask my-house [
    if private-parking? = true [
      hatch-charge-points 1 [
        set shape "electric outlet"
        set color blue
        set size 0.5
        set heading 45
        forward 0.4
        set id-number [ id-number ] of myself
      ]
    ]
  ]

  ; persons that adopt after the initialisation randomly choose an opinion from the distribution results from the survey
  ifelse extreme-scenario-testing? [ ; opinions are set in extreme scenario testing
      set opinion-EV extreme-scenarios-opinions
    ]
    [
      set opinion-EV one-of opinions-EV-list
    ]
  ; they send out new comments to their neighbours about the technologies
  ; depending on how much they discuss with their neighbours (variable neighbours-meet-and-discuss)
  ; and how old their technology is
  ; this influences the emotions of their neighbours about the relevant technologies
  if word-of-mouth? [
    ; positive comments
    if opinion-EV = "PositiveFeedback" or opinion-EV = "MixedFeedback" [
      ask n-of ( round neighbours-meet-and-discuss * number-of-neighbours ) link-neighbors [
        set emotion-EV min list ( max list ( emotion-EV + item 135 person-survey-profile ) 0 ) 1 ]
      ]
    ; negative comments
    if opinion-EV = "NegativeFeedback" or opinion-EV = "MixedFeedback" [
      ask n-of ( round neighbours-meet-and-discuss * number-of-neighbours ) link-neighbors [
        set emotion-EV min list ( max list ( emotion-EV + item 136 person-survey-profile ) 0 ) 1 ]
      ]
   ]

  ; because of the co-adoption factor, persons who decided not to install PV or heat pumps, may want to do so now, so they will re-evaluate
  if setup-complete? and ( owner? OR tenants-can-install ) and
    ( not [ historic? ] of my-house OR historic-houses-can-install-PV ) and
    [ direct-light? ] of my-house and
    not [ PV-solar-panel? ] of my-house and
    not [ thermal-solar-panel? ] of my-house
      [ evaluate-PV-solar-panel ]
  if  setup-complete? and ( owner? OR tenants-can-install ) and
    not [ heating-system-other? ] of my-house and
    not [ thermal-solar-panel? ] of my-house and
    not [ heat-pump? ] of my-house
      [ evaluate-heat-pump ]
  ; update the list for keeping records of which persons adopt EV when
  set adoption-EV-id-list lput id-number adoption-EV-id-list
  ]
end

to adopt-heat-pump
  if [ heat-pump? ] of my-house = false [
    ask my-house [
    set thermal-solar-panel? false
    set heating-system-other? false
    set heating-system-other-age 0
    set heat-pump? true
    hatch-heat-pumps 1 [
      set shape "fire"
      set size 0.5
      set heading 135
      forward 0.4
      set id-number [ id-number ] of myself
    ]
  ]

  ; persons that adopt after the initialisation randomly choose an opinion from the distribution results from the survey
  ifelse extreme-scenario-testing? [ ; opinions are set in extreme scenario testing
      set opinion-heat-pump extreme-scenarios-opinions
    ]
    [
      set opinion-heat-pump one-of opinions-heat-pump-list
    ]
  ; they send out new comments to their neighbours about the technologies
  ; depending on how much they discuss with their neighbours (variable neighbours-meet-and-discuss)
  ; and how old their technology is
  ; this influences the emotions of their neighbours about the relevant technologies
  if word-of-mouth? [
    ; positive comments
    if opinion-heat-pump = "PositiveFeedback" or opinion-heat-pump = "MixedFeedback" [
      ask n-of ( round neighbours-meet-and-discuss * number-of-neighbours ) link-neighbors [
        set emotion-heat-pump min list ( max list ( emotion-heat-pump + item 133 person-survey-profile ) 0 ) 1 ]
      ]
    ; negative comments
    if opinion-heat-pump = "NegativeFeedback" or opinion-heat-pump = "MixedFeedback" [
      ask n-of ( round neighbours-meet-and-discuss * number-of-neighbours ) link-neighbors [
        set emotion-heat-pump min list ( max list ( emotion-heat-pump + item 134 person-survey-profile ) 0 ) 1 ]
      ]
   ]

  ; because of the co-adoption factor, persons who decided not to install PV, may want to do so now, so they will re-evaluate
  if setup-complete? and ( not [ historic? ] of my-house OR historic-houses-can-install-PV ) and
    [ direct-light? ] of my-house and
    not [ PV-solar-panel? ] of my-house and
    not [ thermal-solar-panel? ] of my-house
      [ evaluate-PV-solar-panel ]
  ; update the list for keeping records of which persons adopts a heat-pump when
  set adoption-heat-pump-id-list lput id-number adoption-heat-pump-id-list
  ]
end

to adopt-home-battery
  ask my-house [
    set home-battery? true
    hatch-home-batteries 1 [
      set shape "box"
      set color pink
      set size 0.5
      set heading 225
      forward 0.4
      set id-number [ id-number ] of myself
    ]
  ]
  ; update the list for keeping records of which persons adopts a home battery when
  set adoption-home-battery-id-list lput id-number adoption-home-battery-id-list
end

; ADOPTION EVALUATION FUNCTIONS
	
to evaluate-PV-solar-panel
  ; evaluation model including all factors
  let pv-evaluation ( item 48 person-survey-profile + ; Intercept
    item 49 person-survey-profile * ( price-net-PV / 1000 ) + ; investment cost	
    item 50 person-survey-profile * ( -1 * PV-net-bill-after-adoption ) + ; net bill after investment
    item 51 person-survey-profile * life-cycle-ghg-PV + ; life-cycle greenhouse gas emissions
    item 52 person-survey-profile * [ PV-self-sufficiency-potential-local ] of my-house + ; self-sufficiency (can be increased by home battery)
    ( ifelse-value neighbourhood-effect? [ item 53 person-survey-profile * ( count pv-solar-panels / count houses ) ][ 0 ] ) + ; neighbourhood effect
    item 54 person-survey-profile * item 27 person-survey-profile + ; subjective probability benefit savings
    item 55 person-survey-profile * item 28 person-survey-profile + ; subjective probability benefit independence
    item 56 person-survey-profile * item 28 person-survey-profile + ; subjective probability benefit environment
    item 57 person-survey-profile * item 30 person-survey-profile + ; subjective probability benefit collective action
    item 58 person-survey-profile * item 31 person-survey-profile + ; subjective probability risk high investment costs
    item 59 person-survey-profile * item 32 person-survey-profile + ; subjective probability risk low return on investment costs
    item 60 person-survey-profile * emotion-PV + ; emotions PV
    item 61 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
    item 62 person-survey-profile * item 45 person-survey-profile + ; positive emotions climate change
    ( ifelse-value EV? [ item 63 person-survey-profile ][ 0 ] ) + ; co-adoption: owner of an EV
    ( ifelse-value [ heat-pump? ] of my-house [ item 64 person-survey-profile ][ 0 ] ) ; co-adoption: owner of a heat pump
    )
  if ( 1 / (1 + exp( -1 * pv-evaluation ) ) ) >= ( ifelse-value owner? [ threshold-PV-owner ] [ threshold-PV-tenant ] )
      [ adopt-PV-solar-panel ]
end

to evaluate-EV-small
  ; evaluation model including all factors
  let ev-small-evaluation ( item 65 person-survey-profile + ; Intercept
    item 66 person-survey-profile * ( price-net-EV-small / 1000 ) + ; investment cost	
    item 67 person-survey-profile * savings-EV-small + ; savings on monthly costs after small EV adoption
    item 68 person-survey-profile * life-cycle-ghg-EV + ; life-cycle greenhouse gas emissions
    item 69 person-survey-profile * ( range-EV-small / 100 ) + ; range EVs
    ( ifelse-value neighbourhood-effect? [ item 70 person-survey-profile * ( count EVs / count houses ) ][ 0 ] ) + ; neighbourhood effect
    item 71 person-survey-profile * item 38 person-survey-profile + ; subjective probability benefit savings
    item 72 person-survey-profile * item 39 person-survey-profile + ; subjective probability benefit independence
    item 73 person-survey-profile * item 40 person-survey-profile + ; subjective probability benefit environment
    item 74 person-survey-profile * item 41 person-survey-profile + ; subjective probability benefit collective action
    item 75 person-survey-profile * item 42 person-survey-profile + ; subjective probability risk high investment costs
    item 76 person-survey-profile * item 43 person-survey-profile + ; subjective probability risk low return on investment costs
    item 77 person-survey-profile * emotion-EV + ; emotions EV
    item 78 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
    item 79 person-survey-profile * item 45 person-survey-profile + ; positive emotions climate change
    ( ifelse-value [ PV-solar-panel? ] of my-house [ item 80 person-survey-profile ][ 0 ] )  + ; co-adoption: owner of PV solar panels
    ( ifelse-value [ heat-pump? ] of my-house [ item 81 person-survey-profile ][ 0 ] ) ; co-adoption: owner of a heat pump
  )
  ifelse ( 1 / (1 + exp( -1 * ev-small-evaluation ) ) ) >= threshold-EV-small
      [ adopt-EV ]
      [ adopt-ICE ]
end

to evaluate-EV-medium
  ; evaluation model including all factors
    let ev-medium-evaluation  ( item 82 person-survey-profile + ; Intercept
      item 83 person-survey-profile * ( price-net-EV-medium / 1000 ) + ; investment cost	
      item 84 person-survey-profile * savings-EV-medium + ; savings on monthly costs after medium sized EV adoption
      item 85 person-survey-profile * life-cycle-ghg-EV + ; life-cycle greenhouse gas emissions
      item 86 person-survey-profile * ( range-EV-medium / 100 ) + ; range EVs
      ( ifelse-value neighbourhood-effect? [ item 87 person-survey-profile * ( count EVs / count houses ) ][ 0 ] ) + ; neighbourhood effect
      item 88 person-survey-profile * item 38 person-survey-profile + ; subjective probability benefit savings
      item 89 person-survey-profile * item 39 person-survey-profile + ; subjective probability benefit independence
      item 90 person-survey-profile * item 40 person-survey-profile + ; subjective probability benefit environment
      item 91 person-survey-profile * item 41 person-survey-profile + ; subjective probability benefit collective action
      item 92 person-survey-profile * item 42 person-survey-profile + ; subjective probability risk high investment costs
      item 93 person-survey-profile * item 43 person-survey-profile + ; subjective probability risk low return on investment costs
      item 94 person-survey-profile * emotion-EV + ; emotions EV
      item 95 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
      item 96 person-survey-profile * item 45 person-survey-profile + ; positive emotions climate change
      ( ifelse-value [ PV-solar-panel? ] of my-house [ item 97 person-survey-profile ][ 0 ] )  + ; co-adoption: owner of PV solar panels
      ( ifelse-value [ heat-pump? ] of my-house [ item 98 person-survey-profile ][ 0 ] ) ; co-adoption: owner of a heat pump
    )
   ifelse ( 1 / (1 + exp( -1 * ev-medium-evaluation ) ) ) >= threshold-EV-medium
        [ adopt-EV ]
        [ adopt-ICE ]
end

to evaluate-EV-large
  ; evaluation model including all factors
    let ev-large-evaluation ( item 99 person-survey-profile + ; Intercept
      item 100 person-survey-profile * ( price-net-EV-large / 1000 ) + ; investment cost	
      item 101 person-survey-profile * savings-EV-large + ; savings on monthly costs after large EV adoption
      item 102 person-survey-profile * life-cycle-ghg-EV + ; life-cycle greenhouse gas emissions
      item 103 person-survey-profile * ( range-EV-large / 100 ) + ; range EVs
      ( ifelse-value neighbourhood-effect? [ item 104 person-survey-profile * ( count EVs / count houses ) ][ 0 ] ) + ; neighbourhood effect
      item 105 person-survey-profile * item 38 person-survey-profile + ; subjective probability benefit savings
      item 106 person-survey-profile * item 39 person-survey-profile + ; subjective probability benefit independence
      item 107 person-survey-profile * item 40 person-survey-profile + ; subjective probability benefit environment
      item 108 person-survey-profile * item 41 person-survey-profile + ; subjective probability benefit collective action
      item 109 person-survey-profile * item 42 person-survey-profile + ; subjective probability risk high investment costs
      item 110 person-survey-profile * item 43 person-survey-profile + ; subjective probability risk low return on investment costs
      item 111 person-survey-profile * emotion-EV + ; emotions EV
      item 112 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
      item 113 person-survey-profile * item 45 person-survey-profile + ; positive emotions climate change
      ( ifelse-value [ PV-solar-panel? ] of my-house [ item 114 person-survey-profile ][ 0 ] )  + ; co-adoption: owner of PV solar panels
      ( ifelse-value [ heat-pump? ] of my-house [ item 115 person-survey-profile ][ 0 ] ) ; co-adoption: owner of a heat pump
    )
    ifelse ( 1 / (1 + exp( -1 * ev-large-evaluation ) ) ) >= threshold-EV-large
        [ adopt-EV ]
        [ adopt-ICE ]
end

to evaluate-heat-pump
  ; evaluation model including all factors
    let heat-pump-evaluation ( item 116 person-survey-profile + ; Intercept
      item 117 person-survey-profile * ( price-net-heat-pump / 1000 ) + ; investment cost	
      item 118 person-survey-profile * ( savings-heat-pump / 1000 ) + ; savings on monthly costs after heat pump adoption
      item 119 person-survey-profile * life-cycle-ghg-heat-pump + ; life-cycle greenhouse gas emissions
      ( ifelse-value neighbourhood-effect? [ item 120 person-survey-profile * ( count heat-pumps / count houses ) ][ 0 ] ) + ; neighbourhood effect
      item 121 person-survey-profile * item 33 person-survey-profile + ; subjective probability benefit savings
      item 122 person-survey-profile * item 34 person-survey-profile + ; subjective probability benefit environment
      item 123 person-survey-profile * item 35 person-survey-profile + ; subjective probability benefit collective action
      item 124 person-survey-profile * item 36 person-survey-profile + ; subjective probability risk high investment costs
      item 125 person-survey-profile * item 37 person-survey-profile + ; subjective probability risk low return on investment costs
      item 126 person-survey-profile * emotion-heat-pump + ; emotions heat pump
      item 127 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
      item 128 person-survey-profile * item 45 person-survey-profile + ; positive emotions climate change
      ( ifelse-value EV? [ item 129 person-survey-profile ][ 0 ] )  + ; co-adoption: owner of an EV
      ( ifelse-value [ PV-solar-panel? ] of my-house [ item 130 person-survey-profile ][ 0 ] ) ; co-adoption: owner of a PV solar system
    )
    if ( 1 / (1 + exp( -1 * heat-pump-evaluation ) ) ) >= ( ifelse-value owner? [ threshold-heat-pump-owner ] [ threshold-heat-pump-tenant ] )
        [ adopt-heat-pump ]
end

; ADOPTION EVALUATION FUNCTIONS FOR BUNDLES
; they report a true/false value rather than triggering an adoption action

to-report evaluate-PV-solar-panel-bundle
  ; evaluation model including all factors
    let pv-evaluation ( item 48 person-survey-profile + ; Intercept
      item 49 person-survey-profile * ( price-net-PV / 1000 * ( 1 - bundle-bonus / 100 ) ) + ; investment cost	minus bundle bonus
      item 50 person-survey-profile * ( -1 * PV-net-bill-after-adoption ) + ; net bill after investment
      item 51 person-survey-profile * life-cycle-ghg-PV + ; life-cycle greenhouse gas emissions
      item 52 person-survey-profile * [ PV-self-sufficiency-potential-local ] of my-house + ; self-sufficiency (can be increased by home battery)
      ( ifelse-value neighbourhood-effect? [ item 53 person-survey-profile * ( count pv-solar-panels / count houses ) ][ 0 ] ) + ; neighbourhood effect
      item 54 person-survey-profile * item 27 person-survey-profile + ; subjective probability benefit savings
      item 55 person-survey-profile * item 28 person-survey-profile + ; subjective probability benefit independence
      item 56 person-survey-profile * item 29 person-survey-profile + ; subjective probability benefit environment
      item 57 person-survey-profile * item 30 person-survey-profile + ; subjective probability benefit collective action
      item 58 person-survey-profile * item 31 person-survey-profile + ; subjective probability risk high investment costs
      item 59 person-survey-profile * item 32 person-survey-profile + ; subjective probability risk low return on investment costs
      item 60 person-survey-profile * emotion-PV + ; emotions PV
      item 61 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
      item 62 person-survey-profile * item 45 person-survey-profile + ; positive emotions climate change
      ( ifelse-value EV? [ item 63 person-survey-profile ][ 0 ] ) + ; co-adoption: owner of an EV
      ( ifelse-value [ heat-pump? ] of my-house [ item 64 person-survey-profile ][ 0 ] ) ; co-adoption: owner of a heat pump
    )
    ifelse ( 1 / (1 + exp( -1 * pv-evaluation ) ) ) >= ( ifelse-value owner? [ threshold-PV-owner ] [ threshold-PV-tenant ] )
        [ report true ]
        [ report false ]
end

to-report evaluate-EV-small-bundle
  ; evaluation model including all factors
    let ev-small-evaluation ( item 65 person-survey-profile + ; Intercept
      item 66 person-survey-profile * ( price-net-EV-small / 1000 * ( 1 - bundle-bonus / 100 ) ) + ; investment cost	minus bundle bonus
      item 67 person-survey-profile * savings-EV-small + ; savings on monthly costs after small EV adoption
      item 68 person-survey-profile * life-cycle-ghg-EV + ; life-cycle greenhouse gas emissions
      item 69 person-survey-profile * ( range-EV-small / 100 ) + ; range EVs
      ( ifelse-value neighbourhood-effect? [ item 70 person-survey-profile * ( count EVs / count houses ) ][ 0 ] ) + ; neighbourhood effect
      item 71 person-survey-profile * item 38 person-survey-profile + ; subjective probability benefit savings
      item 72 person-survey-profile * item 39 person-survey-profile + ; subjective probability benefit independence
      item 73 person-survey-profile * item 40 person-survey-profile + ; subjective probability benefit environment
      item 74 person-survey-profile * item 41 person-survey-profile + ; subjective probability benefit collective action
      item 75 person-survey-profile * item 42 person-survey-profile + ; subjective probability risk high investment costs
      item 76 person-survey-profile * item 43 person-survey-profile + ; subjective probability risk low return on investment costs
      item 77 person-survey-profile * emotion-EV + ; emotions EV
      item 78 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
      item 79 person-survey-profile * item 45 person-survey-profile + ; positive emotions climate change
      ( ifelse-value [ PV-solar-panel? ] of my-house [ item 80 person-survey-profile ][ 0 ] )  + ; co-adoption: owner of PV solar panels
      ( ifelse-value [ heat-pump? ] of my-house [ item 81 person-survey-profile ][ 0 ] ) ; co-adoption: owner of a heat pump
    )
    ifelse ( 1 / (1 + exp( -1 * ev-small-evaluation ) ) ) >= threshold-EV-small
        [ report true ]
        [ report false ]
end

to-report evaluate-EV-medium-bundle
  ; evaluation model including all factors
    let ev-medium-evaluation ( item 82 person-survey-profile + ; Intercept
      item 83 person-survey-profile * ( price-net-EV-medium / 1000 * ( 1 - bundle-bonus / 100 ) ) + ; investment cost	minus bundle bonus
      item 84 person-survey-profile * savings-EV-medium + ; savings on monthly costs after medium sized EV adoption
      item 85 person-survey-profile * life-cycle-ghg-EV + ; life-cycle greenhouse gas emissions
      item 86 person-survey-profile * ( range-EV-medium / 100 ) + ; range EVs
      ( ifelse-value neighbourhood-effect? [ item 87 person-survey-profile * ( count EVs / count houses ) ][ 0 ] ) + ; neighbourhood effect
      item 88 person-survey-profile * item 38 person-survey-profile + ; subjective probability benefit savings
      item 89 person-survey-profile * item 39 person-survey-profile + ; subjective probability benefit independence
      item 90 person-survey-profile * item 40 person-survey-profile + ; subjective probability benefit environment
      item 91 person-survey-profile * item 41 person-survey-profile + ; subjective probability benefit collective action
      item 92 person-survey-profile * item 42 person-survey-profile + ; subjective probability risk high investment costs
      item 93 person-survey-profile * item 43 person-survey-profile + ; subjective probability risk low return on investment costs
      item 94 person-survey-profile * emotion-EV + ; emotions EV
      item 95 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
      item 96 person-survey-profile * item 45 person-survey-profile + ; positive emotions climate change
      ( ifelse-value [ PV-solar-panel? ] of my-house [ item 97 person-survey-profile ][ 0 ] )  + ; co-adoption: owner of PV solar panels
      ( ifelse-value [ heat-pump? ] of my-house [ item 98 person-survey-profile ][ 0 ] ) ; co-adoption: owner of a heat pump
    )
    ifelse ( 1 / (1 + exp( -1 * ev-medium-evaluation ) ) ) >= threshold-EV-medium
        [ report true ]
        [ report false ]
end

to-report evaluate-EV-large-bundle
  ; evaluation model including all factors
    let ev-large-evaluation ( item 99 person-survey-profile + ; Intercept
      item 100 person-survey-profile * ( price-net-EV-large / 1000 * ( 1 - bundle-bonus / 100 ) ) + ; investment cost	minus bundle bonus
      item 101 person-survey-profile * savings-EV-large + ; savings on monthly costs after large EV adoption
      item 102 person-survey-profile * life-cycle-ghg-EV + ; life-cycle greenhouse gas emissions
      item 103 person-survey-profile * ( range-EV-large / 100 ) + ; range EVs
      ( ifelse-value neighbourhood-effect? [ item 104 person-survey-profile * ( count EVs / count houses ) ][ 0 ] ) + ; neighbourhood effect
      item 105 person-survey-profile * item 38 person-survey-profile + ; subjective probability benefit savings
      item 106 person-survey-profile * item 39 person-survey-profile + ; subjective probability benefit independence
      item 107 person-survey-profile * item 40 person-survey-profile + ; subjective probability benefit environment
      item 108 person-survey-profile * item 41 person-survey-profile + ; subjective probability benefit collective action
      item 109 person-survey-profile * item 42 person-survey-profile + ; subjective probability risk high investment costs
      item 110 person-survey-profile * item 43 person-survey-profile + ; subjective probability risk low return on investment costs
      item 111 person-survey-profile * emotion-EV + ; emotions EV
      item 112 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
      item 113 person-survey-profile * item 45 person-survey-profile + ; positive emotions climate change
      ( ifelse-value [ PV-solar-panel? ] of my-house [ item 114 person-survey-profile ][ 0 ] )  + ; co-adoption: owner of PV solar panels
      ( ifelse-value [ heat-pump? ] of my-house [ item 115 person-survey-profile ][ 0 ] ) ; co-adoption: owner of a heat pump
    )
    ifelse ( 1 / (1 + exp( -1 * ev-large-evaluation ) ) ) >= threshold-EV-large
        [ report true ]
        [ report false ]
end

to-report evaluate-heat-pump-bundle
  ; evaluation model including all factors
    let heat-pump-evaluation ( item 116 person-survey-profile + ; Intercept
      item 117 person-survey-profile * ( price-net-heat-pump / 1000 * ( 1 - bundle-bonus / 100 ) ) + ; investment cost	minus bundle bonus
      item 118 person-survey-profile * ( savings-heat-pump / 1000 ) + ; savings on monthly costs after heat pump adoption
      item 119 person-survey-profile * life-cycle-ghg-heat-pump + ; life-cycle greenhouse gas emissions
      ( ifelse-value neighbourhood-effect? [ item 120 person-survey-profile * ( count heat-pumps / count houses ) ][ 0 ] ) + ; neighbourhood effect
      item 121 person-survey-profile * item 33 person-survey-profile + ; subjective probability benefit savings
      item 122 person-survey-profile * item 34 person-survey-profile + ; subjective probability benefit environment
      item 123 person-survey-profile * item 35 person-survey-profile + ; subjective probability benefit collective action
      item 124 person-survey-profile * item 36 person-survey-profile + ; subjective probability risk high investment costs
      item 125 person-survey-profile * item 37 person-survey-profile + ; subjective probability risk low return on investment costs
      item 126 person-survey-profile * emotion-heat-pump + ; emotions heat pump
      item 127 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
      item 128 person-survey-profile * item 45 person-survey-profile + ; positive emotions climate change
      ( ifelse-value EV? [ item 129 person-survey-profile ][ 0 ] )  + ; co-adoption: owner of an EV
      ( ifelse-value [ PV-solar-panel? ] of my-house [ item 130 person-survey-profile ][ 0 ] ) ; co-adoption: owner of a PV solar system
  )
  ifelse ( 1 / (1 + exp( -1 * heat-pump-evaluation ) ) ) >= ( ifelse-value owner? [ threshold-heat-pump-owner ] [ threshold-heat-pump-tenant ] )
        [ report true ]
        [ report false ]
end
@#$#@#$#@
GRAPHICS-WINDOW
267
10
943
687
-1
-1
8.68
1
10
1
1
1
0
1
1
1
-38
38
-38
38
1
1
1
ticks
30.0

BUTTON
7
13
259
46
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
6
50
69
83
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
78
52
141
85
NIL
go
NIL
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
5
113
255
146
households
households
0
1469
1469.0
1
1
NIL
HORIZONTAL

SLIDER
7
152
257
185
number-of-neighbours
number-of-neighbours
0
20
20.0
1
1
NIL
HORIZONTAL

PLOT
970
517
1521
737
net prices
NIL
NIL
0.0
29.0
0.0
125000.0
true
true
"" ""
PENS
"PV" 1.0 0 -4079321 true "" "plot price-net-PV"
"Heat pump" 1.0 0 -955883 true "" "plot price-net-heat-pump"
"large EVs" 1.0 0 -13210332 true "" "plot price-net-EV-large"
"medium sized EVs" 1.0 0 -10899396 true "" "plot price-net-EV-medium"
"small EVs" 1.0 0 -8330359 true "" "plot price-net-EV-small"

SWITCH
9
411
232
444
historic-houses-can-install-PV
historic-houses-can-install-PV
0
1
-1000

SWITCH
9
370
189
403
tenants-can-install
tenants-can-install
0
1
-1000

SLIDER
6
530
231
563
learning-rate-life-cycle-ghg-PV
learning-rate-life-cycle-ghg-PV
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
8
491
233
524
PV-net-bill-after-adoption
PV-net-bill-after-adoption
-1000
1000
-489.0
1
1
CHF / year
HORIZONTAL

SLIDER
9
573
255
606
PV-self-sufficiency-potential-global
PV-self-sufficiency-potential-global
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
11
452
235
485
subsidy-PV
subsidy-PV
0
100
0.0
1
1
%
HORIZONTAL

SLIDER
416
697
620
730
subsidy-EV
subsidy-EV
0
300
0.0
1
1
%
HORIZONTAL

SLIDER
415
737
623
770
savings-EV-small
savings-EV-small
0
15
3.3
0.1
1
CHF / 100 km
HORIZONTAL

SLIDER
415
775
625
808
savings-EV-medium
savings-EV-medium
0
15
3.7
0.1
1
CHF / 100 km
HORIZONTAL

SLIDER
415
813
625
846
savings-EV-large
savings-EV-large
0
15
4.1
0.1
1
CHF / 100 km
HORIZONTAL

SLIDER
627
699
842
732
learning-rate-life-cycle-ghg-EV
learning-rate-life-cycle-ghg-EV
0
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
9
689
237
722
subsidy-heat-pump
subsidy-heat-pump
0
100
33.0
1
1
%
HORIZONTAL

SLIDER
9
727
235
760
savings-heat-pump
savings-heat-pump
0
3000
2090.0
1
1
CHF / year
HORIZONTAL

SLIDER
7
765
239
798
learning-rate-life-cycle-ghg-heat-pump
learning-rate-life-cycle-ghg-heat-pump
0
1
0.02
0.01
1
NIL
HORIZONTAL

INPUTBOX
153
47
258
107
stop-after-x-years
29.0
1
0
Number

PLOT
966
284
1501
509
co-adoption
NIL
NIL
0.0
29.0
0.0
500.0
true
true
"" ""
PENS
"PV + HP + EV" 1.0 0 -16777216 true "" "plot count persons with [ [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and EV? ]"
"PV + HP" 1.0 0 -955883 true "" "plot count persons with [ [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and not EV? ]"
"PV + EV" 1.0 0 -10899396 true "" "plot count persons with [ [ PV-solar-panel? ] of my-house and not [ heat-pump? ] of my-house and EV? ]"
"HP + EV" 1.0 0 -8630108 true "" "plot count persons with [ not [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and EV? ]"
"PV" 1.0 0 -4079321 true "" "plot count persons with [ [ PV-solar-panel? ] of my-house and not [ heat-pump? ] of my-house and not EV? ] "
"HP" 1.0 0 -2674135 true "" "plot count persons with [ not [ PV-solar-panel? ] of my-house and [ heat-pump? ] of my-house and not EV? ]"
"EV" 1.0 0 -13345367 true "" "plot count persons with [ not [ PV-solar-panel? ] of my-house and not [ heat-pump? ] of my-house and EV? ]"

SWITCH
10
202
192
235
neighbourhood-effect?
neighbourhood-effect?
0
1
-1000

SWITCH
13
240
195
273
word-of-mouth?
word-of-mouth?
0
1
-1000

PLOT
964
15
1655
280
adoption
NIL
NIL
0.0
29.0
0.0
1500.0
true
true
"" ""
PENS
"PV" 1.0 0 -4079321 true "" "plot count pv-solar-panels"
"Heat pump" 1.0 0 -955883 true "" "plot count heat-pumps"
"EVs total" 1.0 0 -15456499 true "" "plot count EVs"
"Large EVs" 1.0 0 -13210332 true "" "plot count EVs with [ car-size = \"Big car\" ]"
"Medium sized EVs" 1.0 0 -10899396 true "" "plot count EVs with [ car-size = \"Medium car\" ]"
"Small EVs" 1.0 0 -6565750 true "" "plot count EVs with [ car-size = \"Small car\" ]"
"HEVs" 1.0 0 -14835848 true "" "plot count HEVs"
"ICEs" 1.0 0 -11053225 true "" "plot count ICEs"
"Thermal solar panels & other heating systems" 1.0 0 -5825686 true "" "plot count houses with [ heating-system-other? = true ] + count thermal-solar-panels"
"Charge points" 1.0 0 -13791810 true "" "plot count charge-points"
"Home batteries" 1.0 0 -2064490 true "" "plot count home-batteries"

SLIDER
10
805
244
838
information-campaign-heat-pump-year
information-campaign-heat-pump-year
2022
2051
2051.0
1
1
NIL
HORIZONTAL

SLIDER
628
737
843
770
information-campaign-EV-year
information-campaign-EV-year
2022
2051
2051.0
1
1
NIL
HORIZONTAL

SLIDER
12
616
236
649
information-campaign-PV-year
information-campaign-PV-year
2022
2051
2051.0
1
1
NIL
HORIZONTAL

SLIDER
11
329
188
362
bundle-bonus
bundle-bonus
0
100
100.0
1
1
%
HORIZONTAL

SLIDER
632
774
844
807
range-EV-increase
range-EV-increase
0
50
20.0
1
1
km / yr
HORIZONTAL

PLOT
1576
295
1755
445
emotion PV
NIL
NIL
0.0
1.1
0.0
1500.0
true
false
"" ""
PENS
"PV" 0.1 1 -16777216 true "" "histogram [ emotion-PV ] of persons"

PLOT
1585
453
1759
603
emotion EV
NIL
NIL
0.0
1.1
0.0
1500.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [ emotion-EV ] of persons"

PLOT
1588
609
1765
759
emotion heat pump
NIL
NIL
0.0
1.1
0.0
1500.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [ emotion-heat-pump ] of persons"

SLIDER
11
287
217
320
stimulate-social-interaction
stimulate-social-interaction
0
1
1.0
0.01
1
NIL
HORIZONTAL

SWITCH
975
786
1176
819
extreme-scenario-testing?
extreme-scenario-testing?
1
1
-1000

CHOOSER
975
825
1171
870
extreme-scenario-prices
extreme-scenario-prices
"low" "high"
1

CHOOSER
1184
875
1384
920
extreme-scenario-savings
extreme-scenario-savings
"low" "high"
1

CHOOSER
1181
827
1491
872
extreme-scenario-neighbours-meet-and-discuss
extreme-scenario-neighbours-meet-and-discuss
0 1
1

CHOOSER
1179
777
1356
822
extreme-scenarios-opinions
extreme-scenarios-opinions
"PositiveFeedback" "NegativeFeedback"
0

CHOOSER
978
876
1170
921
extreme-scenario-GHG
extreme-scenario-GHG
"low" "high"
0

CHOOSER
1392
876
1569
921
extreme-scenario-EV-range
extreme-scenario-EV-range
200 700
1

SWITCH
1377
782
1658
815
extreme-scenario-information-campaign?
extreme-scenario-information-campaign?
1
1
-1000

CHOOSER
442
871
580
916
savings-EV
savings-EV
"low" "medium" "high"
0

TEXTBOX
977
745
1127
763
extreme scenarios
11
0.0
1

TEXTBOX
987
931
1137
949
Sensitivity analysis
11
0.0
0

SLIDER
969
990
1185
1023
sensitivity-learning-rate-PV
sensitivity-learning-rate-PV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
970
1028
1186
1061
sensitivity-learning-rate-EV
sensitivity-learning-rate-EV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
922
1067
1184
1100
sensitivity-learning-rate-heat-pump
sensitivity-learning-rate-heat-pump
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1191
989
1385
1022
sensitivity-price-min-PV
sensitivity-price-min-PV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1196
1026
1390
1059
sensitivity-price-min-EV
sensitivity-price-min-EV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1194
1067
1434
1100
sensitivity-price-min-heat-pump
sensitivity-price-min-heat-pump
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
951
1254
1192
1287
sensitivity-learning-rate-ghg-PV
sensitivity-learning-rate-ghg-PV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
953
1296
1194
1329
sensitivity-learning-rate-ghg-EV
sensitivity-learning-rate-ghg-EV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
908
1335
1195
1368
sensitivity-learning-rate-ghg-heat-pump
sensitivity-learning-rate-ghg-heat-pump
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1207
1256
1395
1289
sensitivity-min-ghg-PV
sensitivity-min-ghg-PV
0
200
100.0
1
1
%
HORIZONTAL

SWITCH
983
949
1148
982
sensitivity-analysis?
sensitivity-analysis?
0
1
-1000

SLIDER
1208
1295
1396
1328
sensitivity-min-ghg-EV
sensitivity-min-ghg-EV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1208
1333
1442
1366
sensitivity-min-ghg-heat-pump
sensitivity-min-ghg-heat-pump
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1001
1104
1187
1137
sensitivity-subsidy-PV
sensitivity-subsidy-PV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1002
1143
1188
1176
sensitivity-subsidy-EV
sensitivity-subsidy-EV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
947
1181
1187
1214
sensitivity-subsidy-heat-pump
sensitivity-subsidy-heat-pump
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1196
1105
1462
1138
sensitivity-PV-net-bill-after-adoption
sensitivity-PV-net-bill-after-adoption
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1196
1141
1382
1174
sensitivity-savings-EV
sensitivity-savings-EV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1197
1177
1429
1210
sensitivity-savings-heat-pump
sensitivity-savings-heat-pump
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1470
985
1719
1018
sensitivity-number-of-neighbours
sensitivity-number-of-neighbours
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1470
1068
1697
1101
sensitivity-range-EV-increase
sensitivity-range-EV-increase
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1472
1106
1676
1139
sensitivity-range-EV-max
sensitivity-range-EV-max
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1469
1028
1749
1061
sensitivity-PV-self-sufficiency-potential
sensitivity-PV-self-sufficiency-potential
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1474
1147
1785
1180
sensitivity-replacement-time-heating-system
sensitivity-replacement-time-heating-system
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1097
1216
1298
1249
sensitivity-bundle-bonus
sensitivity-bundle-bonus
0
200
100.0
1
1
%
HORIZONTAL

SWITCH
1159
943
1316
976
replacement-time?
replacement-time?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

computer workstation
false
0
Rectangle -7500403 true true 60 45 240 180
Polygon -7500403 true true 90 180 105 195 135 195 135 210 165 210 165 195 195 195 210 180
Rectangle -16777216 true false 75 60 225 165
Rectangle -7500403 true true 45 210 255 255
Rectangle -10899396 true false 249 223 237 217
Line -16777216 false 60 225 120 225

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

electric outlet
false
0
Rectangle -7500403 true true 45 0 255 297
Polygon -16777216 false false 120 270 90 240 90 195 120 165 180 165 210 195 210 240 180 270
Rectangle -16777216 true false 169 199 177 236
Rectangle -16777216 true false 169 64 177 101
Polygon -16777216 false false 120 30 90 60 90 105 120 135 180 135 210 105 210 60 180 30
Rectangle -16777216 true false 123 64 131 101
Rectangle -16777216 true false 123 199 131 236
Rectangle -16777216 false false 45 0 255 296

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

lightning
false
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="baseline_validation" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>count PV-solar-panels</metric>
    <metric>count EVs</metric>
    <metric>count heat-pumps</metric>
    <metric>count home-batteries</metric>
    <metric>co-adoption-PV-EV-heat-pump</metric>
    <metric>co-adoption-PV-EV</metric>
    <metric>co-adoption-PV-heat-pump</metric>
    <metric>co-adoption-EV-heat-pump</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2090"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="-489"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>adoption-PV-id-list</metric>
    <metric>adoption-EV-id-list</metric>
    <metric>adoption-heat-pump-id-list</metric>
    <metric>adoption-home-battery-id-list</metric>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2022"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-price-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-price-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-price-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="-90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2022"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2022"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighours">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="main" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>adoption-PV-id-list</metric>
    <metric>adoption-EV-id-list</metric>
    <metric>adoption-heat-pump-id-list</metric>
    <metric>adoption-home-battery-id-list</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-PV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-EV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-price-min-PV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-price-min-EV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-price-min-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-subsidy-PV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-subsidy-EV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-subsidy-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-PV-net-bill-after-adoption" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-savings-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-ghg-PV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-ghg-EV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-ghg-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-number-of-neighbours" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-PV-self-sufficiency-potential" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-range-EV-increase" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-range-EV-max" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-replacement-time-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-neighbourhood-effect" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-word-of-mouth" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-bundle-bonus" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-savings-EV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="main-sensitivity" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="main-sensitivity-output-test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>adoption-PV-id-list</metric>
    <metric>adoption-EV-id-list</metric>
    <metric>adoption-heat-pump-id-list</metric>
    <metric>count PV-solar-panels</metric>
    <metric>count EVs</metric>
    <metric>count heat-pumps</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-replacement-time-at-all" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>adoption-PV-id-list</metric>
    <metric>adoption-EV-id-list</metric>
    <metric>adoption-heat-pump-id-list</metric>
    <metric>adoption-home-battery-id-list</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
