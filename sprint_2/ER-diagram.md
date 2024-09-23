[!ER-diagram](er-diagram.png)

```

Enum "cafe"."restaurant_type" {
  "coffee_shop"
  "restaurant"
  "bar"
  "pizzeria"
}

Table "cafe"."districts" {
  "id" serial4 [not null]
  "name" varchar(255) [not null]
  "geom" public.geometry

  Indexes {
    id [pk, name: "districts_pkey"]
  }
}

Table "cafe"."managers" {
  "uuid" uuid [not null, default: `gen_random_uuid()`]
  "full_name" varchar(50) [not null]
  "phone" varchar(50)

  Indexes {
    uuid [pk, name: "managers_pkey"]
  }
}

Table "cafe"."restaurants" {
  "uuid" uuid [not null, default: `gen_random_uuid()`]
  "district_id" int4 [not null]
  "name" varchar(50) [not null]
  "type" cafe.restaurant_type [not null]
  "menu" jsonb [not null]
  "location" public.geometry

  Indexes {
    name [unique, name: "restaurants_name_key"]
    uuid [pk, name: "restaurants_pkey"]
  }
}

Table "cafe"."sales" {
  "restaurant_uuid" uuid [not null]
  "date" date [not null]
  "avg_check" numeric(6,2) [not null]

  Indexes {
    (restaurant_uuid, date) [pk, name: "sales_pkey"]
  }
}

Table "cafe"."restaurant_manager_work_dates" {
  "restaurant_uuid" uuid [not null]
  "manager_uuid" uuid [not null]
  "date_start" date [not null]
  "date_end" date [not null]

  Indexes {
    (restaurant_uuid, manager_uuid) [pk, name: "restaurant_manager_work_dates_pkey"]
  }
}

Ref "restaurants_district_id_fkey":"cafe"."districts"."id" < "cafe"."restaurants"."district_id"

Ref "sales_restaurant_uuid_fkey":"cafe"."restaurants"."uuid" < "cafe"."sales"."restaurant_uuid"

Ref "restaurant_manager_work_dates_manager_uuid_fkey":"cafe"."managers"."uuid" < "cafe"."restaurant_manager_work_dates"."manager_uuid"

Ref "restaurant_manager_work_dates_restaurant_uuid_fkey":"cafe"."restaurants"."uuid" < "cafe"."restaurant_manager_work_dates"."restaurant_uuid"
```