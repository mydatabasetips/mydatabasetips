set pages 200
set lines 300

select 'alter table '||a.owner||'.'||a.table_name||' disable constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='SM_OWNER'
and b.table_name in 
(
'B_DISTRIBUTOR_ITEM_PRODUCT'
,'B_DISTRIBUTOR_UNIT'
,'D_DISTRIBUTOR'
,'D_DISTRIBUTOR_ITEM'
,'D_DISTRIBUTOR_PRODUCT'
,'D_GPO_CODE'
,'D_GPO_GROUP'
,'D_GPO_ROLLUP'
,'D_INVOICE_CUSTOMER'
,'D_MANUFACTURER'
,'D_MANUFACTURER_PRODUCT'
,'D_PRICE_AUDIT_TRN_HDR'
,'D_PRICE_CONTRACT'
,'D_PRICE_CONTRACT_EXCEPTION'
,'D_PRICE_CONTRACT_RATE'
,'D_PRICE_PROGRAM'
,'D_PRODUCT'
,'D_PRODUCT_FAMILY'
,'D_PRODUCT_FAMILY_TYPE'
,'D_PRODUCT_SUB_FAMILY_TYPE'
,'D_PRODUCT_SUB_SUB_FAMILY_TYPE'
,'D_PURCHASE_POS_FLAG'
,'D_PURCHASING_ENTITY'
,'D_PURCHASING_UNIT'
,'D_VENDOR_PRODUCT'
,'F_POS_SPEND_AUDIT'
,'F_PURCHASE_INVOICE_DTL'
,'F_PURCHASE_POS_CONTRACT_FLAG'
,'F_PURCHASE_POS_DTL'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' disable constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='AR_STAGE'
and b.table_name in 
(
'S_AR_CATALOG_CURR'
,'S_AR_PROD_XREF'
,'S_VAT_ALL_EFM_SHARE_RATES'
,'S_VAT_EFM_RATE'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' disable constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='EDW'
and b.table_name in 
(
'D_CUSTOMER'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' disable constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='GRPT_OWNER'
and b.table_name in 
(
'D_DIVISION'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' disable constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='PIM_OWNER'
and b.table_name in 
(
'B_PIM_PCC_CATALOG_DAT'
,'D_PIM_ALLERGEN'
,'D_PIM_DIET_TYPE'
,'D_PIM_MANUFACTURER_ITEM'
,'D_PIM_NUTRIENT'
,'F_ITEM_ALLERGEN_VALUE'
,'F_ITEM_DIET_VALUE'
,'F_ITEM_NUTRIENT_VALUE'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' disable constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='SM_STAGE'
and b.table_name in 
(
'S_SM_ENT_VDA_SLE'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' disable constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='TMC_OWNER'
and b.table_name in 
(
'B_VAT_DISTRB_BRAND_FLAG'
,'D_CATALOG_FLAG'
);


--enable

set pages 200
set lines 300


select 'alter table '||a.owner||'.'||a.table_name||' enable novalidate constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='SM_OWNER'
and b.table_name in 
(
'B_DISTRIBUTOR_ITEM_PRODUCT'
,'B_DISTRIBUTOR_UNIT'
,'D_DISTRIBUTOR'
,'D_DISTRIBUTOR_ITEM'
,'D_DISTRIBUTOR_PRODUCT'
,'D_GPO_CODE'
,'D_GPO_GROUP'
,'D_GPO_ROLLUP'
,'D_INVOICE_CUSTOMER'
,'D_MANUFACTURER'
,'D_MANUFACTURER_PRODUCT'
,'D_PRICE_AUDIT_TRN_HDR'
,'D_PRICE_CONTRACT'
,'D_PRICE_CONTRACT_EXCEPTION'
,'D_PRICE_CONTRACT_RATE'
,'D_PRICE_PROGRAM'
,'D_PRODUCT'
,'D_PRODUCT_FAMILY'
,'D_PRODUCT_FAMILY_TYPE'
,'D_PRODUCT_SUB_FAMILY_TYPE'
,'D_PRODUCT_SUB_SUB_FAMILY_TYPE'
,'D_PURCHASE_POS_FLAG'
,'D_PURCHASING_ENTITY'
,'D_PURCHASING_UNIT'
,'D_VENDOR_PRODUCT'
,'F_POS_SPEND_AUDIT'
,'F_PURCHASE_INVOICE_DTL'
,'F_PURCHASE_POS_CONTRACT_FLAG'
,'F_PURCHASE_POS_DTL'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' enable novalidate constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='AR_STAGE'
and b.table_name in 
(
'S_AR_CATALOG_CURR'
,'S_AR_PROD_XREF'
,'S_VAT_ALL_EFM_SHARE_RATES'
,'S_VAT_EFM_RATE'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' enable novalidate constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='EDW'
and b.table_name in 
(
'D_CUSTOMER'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' enable novalidate constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='GRPT_OWNER'
and b.table_name in 
(
'D_DIVISION'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' enable novalidate constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='PIM_OWNER'
and b.table_name in 
(
'B_PIM_PCC_CATALOG_DAT'
,'D_PIM_ALLERGEN'
,'D_PIM_DIET_TYPE'
,'D_PIM_MANUFACTURER_ITEM'
,'D_PIM_NUTRIENT'
,'F_ITEM_ALLERGEN_VALUE'
,'F_ITEM_DIET_VALUE'
,'F_ITEM_NUTRIENT_VALUE'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' enable novalidate constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='SM_STAGE'
and b.table_name in 
(
'S_SM_ENT_VDA_SLE'
)
union
select 'alter table '||a.owner||'.'||a.table_name||' enable novalidate constraint '||a.constraint_name||';'
from all_constraints a, all_constraints b
where a.constraint_type = 'R' and a.status='ENABLED'
and a.r_constraint_name = b.constraint_name
and a.r_owner  = b.owner
and b.owner='TMC_OWNER'
and b.table_name in 
(
'B_VAT_DISTRB_BRAND_FLAG'
,'D_CATALOG_FLAG'
);


