BEGIN;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


SET search_path = imc, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;











CREATE OR REPLACE FUNCTION imc_trf_universal_insert() RETURNS trigger AS $imc_trf_universal_insert$
    DECLARE
        created_time                timestamp without time zone;
        cur_max_order_in_list       integer;
        duplicates_count            integer;
        row_count                   integer;
        sel_count                   integer;

        deleted_order_in_list       integer;
        query                       text;
        pk_column_name              text;
        --pk_value                    uuid;
        --pk_value_text               text;
        text_var1                   text;
        text_var2                   text;
        text_var3                   text;
        stack                       text;
        _rec                        record;
        _rec1                       record;


    BEGIN
        
        created_time := date_trunc('second'::text, now());


        IF TG_TABLE_SCHEMA = 'imc' 
        THEN 

            RAISE NOTICE  'Trigger ''%'', таблица ''%'': Старт.', TG_NAME, TG_TABLE_NAME;

            IF TG_TABLE_NAME = 'dc_kinds'  OR 
               TG_TABLE_NAME = 'sfet_ls_kinds' OR 
               TG_TABLE_NAME = 'sfet_prop_val_types' OR 
               TG_TABLE_NAME = 'ict_cnf_param_val_types' OR  
               TG_TABLE_NAME = 'icts_calculation_rules_kinds' OR 
               TG_TABLE_NAME = 'icts_calculation_rules_allowed_operands' OR 
               TG_TABLE_NAME = 'access_objects_kinds' OR 
               TG_TABLE_NAME = 'access_objects_acts_kinds' 
            THEN
                -- RAISE EXCEPTION 'Trigger ''%'': Table ''%'' is dictionary and for read only.', TG_NAME, TG_TABLE_NAME;
                RAISE EXCEPTION 'Trigger ''%'': Таблица ''%'' является словарем и предназначена только для чтения.', TG_NAME, TG_TABLE_NAME;
                RETURN NULL;



            ELSIF TG_TABLE_NAME = 'thematic_layers'
            THEN
                INSERT INTO imc.changing_history(id_changing, id_layer, id_model, changed, changed_by) 
                VALUES (public.uuid_generate_v4(), NEW.id_layer, NULL, created_time, NEW.changed_by);

                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE  'Trigger ''%'': row_count = ''%'' .', TG_NAME, row_count;

                IF row_count  <> 1
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка вставки записи в таблицу ''changing_history'' о добавлении новой записи в таблицу ''thematic_layers''.', TG_NAME;
                    RETURN NULL;
                END IF;

            ELSIF TG_TABLE_NAME = 'thematic_layers_sfes'
            THEN
                UPDATE imc.thematic_layers AS t
                SET t.changed = created_time, t.changed_by = NEW.changed_by
                WHERE t.id_layer = NEW.id_layer;

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке добавления в таблицу ''%'', ошибка при связанном обновлении таблицы ''thematic_layers''.', TG_NAME, TG_TABLE_NAME;
                    RETURN NULL;
                END IF;

            ELSIF TG_TABLE_NAME = 'thematic_layers_sfe_linkings'  OR 
                  TG_TABLE_NAME = 'thematic_layers_sfe_properties' 
            THEN
                UPDATE imc.thematic_layers AS t
                SET t.changed = created_time, t.changed_by = NEW.changed_by
                WHERE t.id_layer = (SELECT s.id_layer FROM imc.thematic_layers_sfes s WHERE s.id_sfe = NEW.id_sfe);

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке добавления в таблицу ''%'', ошибка при связанном обновлении таблицы ''thematic_layers''.', TG_NAME, TG_TABLE_NAME;
                    RETURN NULL;
                END IF;

                IF TG_TABLE_NAME = 'thematic_layers_sfe_properties'
                THEN
                    IF NEW.val IS NOT NULL AND NEW.val_by_id_pvd_record IS NOT NULL
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке добавления в таблицу ''thematic_layers_sfe_properties'' обнаружено, что одновременно заданы не NULL поля ''val'' и ''val_by_id_pvd_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;
                END IF;


                IF TG_TABLE_NAME = 'thematic_layers_sfe_linkings'
                THEN

                    IF NEW.id_ls_sfe IS NULL AND NEW.id_ls_aec_record IS NULL
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке добавления в таблицу ''thematic_layers_sfe_linkings'' обнаружено, что одновременно заданы как NULL поля ''id_ls_sfe'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                    IF NEW.id_ls_sfe IS NOT NULL
                    THEN
                            -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_sfe

                        /*
                        SELECT INTO duplicates_count count(*)
                        FROM imc.thematic_layers_sfe_linkings t
                        WHERE t.id_sfe = NEW.id_sfe
                          AND t.id_sfet_linking = NEW.id_sfet_linking
                          AND t.id_lmd_record = NEW.id_lmd_record
                          AND t.id_ls_sfe = NEW.id_ls_sfe;
                          */

                        duplicates_count := 0;

                        EXECUTE format(
                                   '
                                   SELECT count(*)
                                   FROM imc.thematic_layers_sfe_linkings t
                                   WHERE t.id_sfe = %I
                                     AND t.id_sfet_linking = %I
                                     AND t.id_lmd_record = %I
                                     AND t.id_ls_sfe = %I;
                                  ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_lmd_record)
                                  INTO  duplicates_count;
 
                        RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;
                        
                        GET DIAGNOSTICS row_count = ROW_COUNT;
        
                        IF row_count <> 1 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''imc.thematic_layers_sfe_linkings''.', TG_NAME;
                            RETURN NULL;
                        END IF;

                        IF duplicates_count > 0 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Запись, добавляемая в таблицу ''thematic_layers_sfe_linkings'', дублирует существующую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_sfe'', что недопустимо.', TG_NAME ;
                            RETURN NULL;
                        END IF;

                    ELSIF NEW.id_ls_aec_record IS NOT NULL
                    THEN

                            -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_aec_record

                        /*
                        SELECT INTO duplicates_count count(*)
                        FROM imc.thematic_layers_sfe_linkings t
                        WHERE t.id_sfe = NEW.id_sfe
                          AND t.id_sfet_linking = NEW.id_sfet_linking
                          AND t.id_lmd_record = NEW.id_lmd_record
                          AND t.id_ls_aec_record = NEW.id_ls_aec_record;
                          */

                        duplicates_count := 0;

                        EXECUTE format(
                                   '
                                   SELECT count(*)
                                   FROM imc.thematic_layers_sfe_linkings t
                                   WHERE t.id_sfe = %I
                                    AND t.id_sfet_linking = %I
                                    AND t.id_lmd_record = %I
                                    AND t.id_ls_aec_record = %I;
                                  ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_ls_aec_record)
                                  INTO  duplicates_count;
 
                        RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;
-- TO DO Check errors
                        GET DIAGNOSTICS row_count = ROW_COUNT;
        
                        IF row_count <> 1 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''imc.thematic_layers_sfe_linkings''.', TG_NAME;
                            RETURN NULL;
                        END IF;

                       IF duplicates_count > 0 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Запись, добавляемая в таблицу ''thematic_layers_sfe_linkings'', дублирует существующую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                            RETURN NULL;
                        END IF;

                    END IF;

                END IF;


            ELSIF TG_TABLE_NAME = 'models'
            THEN
                INSERT INTO imc.changing_history(id_changing, id_layer, id_model, changed, changed_by) 
                VALUES (public.uuid_generate_v4(), NULL, NEW.id_model, created_time, NEW.changed_by);

                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE  'Trigger ''%'': row_count = ''%'' .', TG_NAME, row_count;

                IF row_count  <> 1
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка вставки записи в таблицу ''changing_history'' о добавлении новой записи в таблицу ''thematic_layers''.', TG_NAME;
                    RETURN NULL;
                END IF;


            ELSIF TG_TABLE_NAME = 'models_sfe'
            THEN
                UPDATE imc.models AS t
                SET t.changed = created_time, t.changed_by = NEW.changed_by
                WHERE t.id_model = NEW.id_model;

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'':Ошибка при попытке добавления в таблицу ''%'', ошибка при связанном обновлении таблицы ''models''.', TG_NAME, TG_TABLE_NAME;
                    RETURN NULL;
                END IF;


            ELSIF TG_TABLE_NAME = 'models_sfe_linkings'  OR 
                  TG_TABLE_NAME = 'models_sfe_properties'
            THEN
                UPDATE imc.models AS t
                SET t.changed = created_time, t.changed_by = NEW.changed_by
                WHERE t.id_model = (SELECT s.id_model FROM imc.models_sfe s WHERE s.id_sfe = NEW.id_sfe);

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке добавления в таблицу ''%'', ошибка при связанном обновлении таблицы ''models''.', TG_NAME, TG_TABLE_NAME;
                    RETURN NULL;
                END IF;

                IF TG_TABLE_NAME = 'models_sfe_properties'
                THEN
                    IF NEW.val IS NOT NULL AND NEW.val_by_id_pvd_record IS NOT NULL
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке добавления в таблицу ''models_sfe_properties'' обнаружено, что одновременно заданы не NULL поля ''val'' и ''val_by_id_pvd_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;
                END IF;


                IF TG_TABLE_NAME = 'models_sfe_linkings'
                THEN

                    IF NEW.id_ls_sfe IS NULL AND NEW.id_ls_aec_record IS NULL
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке добавления в таблицу ''models_sfe_linkings'' обнаружено, что одновременно заданы как NULL поля ''id_ls_sfe'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                    IF NEW.id_ls_sfe IS NOT NULL
                    THEN
                            -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_sfe

                        /*
                        SELECT INTO duplicates_count count(*)
                        FROM imc.models_sfe_linkings t
                        WHERE t.id_sfe = NEW.id_sfe
                          AND t.id_sfet_linking = NEW.id_sfet_linking
                          AND t.id_lmd_record = NEW.id_lmd_record
                          AND t.id_ls_sfe = NEW.id_ls_sfe;
                        */

                        duplicates_count := 0;

                        EXECUTE format(
                                   '
                                    SELECT count(*)
                                    FROM imc.models_sfe_linkings t
                                    WHERE t.id_sfe = %I
                                        AND t.id_sfet_linking = %I
                                        AND t.id_lmd_record = %I
                                        AND t.id_ls_sfe = %I;
                                  ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_ls_sfe)
                                  INTO  duplicates_count;
 
                        RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;

                        GET DIAGNOSTICS row_count = ROW_COUNT;
        
                        IF row_count <> 1 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''models_sfe_linkings''.', TG_NAME;
                            RETURN NULL;
                        END IF;

                        IF duplicates_count > 0 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Запись, добавляемая в таблицу ''models_sfe_linkings'', дублирует существующую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_sfe'', что недопустимо.', TG_NAME ;
                            RETURN NULL;
                        END IF;

                    ELSIF NEW.id_ls_aec_record IS NOT NULL
                    THEN

                            -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_aec_record
                        /*
                        SELECT INTO duplicates_count count(*)
                        FROM imc.models_sfe_linkings t
                        WHERE t.id_sfe = NEW.id_sfe
                          AND t.id_sfet_linking = NEW.id_sfet_linking
                          AND t.id_lmd_record = NEW.id_lmd_record
                          AND t.id_ls_aec_record = NEW.id_ls_aec_record;
                        */

                        duplicates_count := 0;

                        EXECUTE format(
                                   '
                                    SELECT count(*)
                                    FROM imc.models_sfe_linkings t
                                    WHERE t.id_sfe = %I
                                        AND t.id_sfet_linking = %I
                                        AND t.id_lmd_record = %I
                                        AND t.id_ls_sfe = %I;
                                  ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_ls_aec_record)
                                  INTO  duplicates_count;
 
                        RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;

                        GET DIAGNOSTICS row_count = ROW_COUNT;
        
                        IF row_count <> 1 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''models_sfe_linkings''.', TG_NAME;
                            RETURN NULL;
                        END IF;

                        IF duplicates_count > 0 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Запись, добавляемая в таблицу ''models_sfe_linkings'', дублирует существующую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                            RETURN NULL;
                        END IF;

                    END IF;
                END IF;


            ELSIF TG_TABLE_NAME = 'resulting_models_sfe_linkings'
            THEN

                IF NEW.id_ls_sfe IS NULL AND NEW.id_ls_aec_record IS NULL
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке добавления в таблицу ''resulting_models_sfe_linkings'' обнаружено, что одновременно заданы как NULL поля ''id_ls_sfe'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                    RETURN NULL;
                END IF;

                IF NEW.id_ls_sfe IS NOT NULL
                THEN
                        -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_sfe
                    /*
                    SELECT INTO duplicates_count count(*)
                    FROM imc.resulting_models_sfe_linkings t
                    WHERE t.id_sfe = NEW.id_sfe
                      AND t.id_sfet_linking = NEW.id_sfet_linking
                      AND t.id_lmd_record = NEW.id_lmd_record
                      AND t.id_ls_sfe = NEW.id_ls_sfe;
                    */

                    duplicates_count := 0;

                    EXECUTE format(
                                   '
                                    SELECT count(*)
                                    FROM imc.resulting_models_sfe_linkings t
                                    WHERE t.id_sfe = %I
                                        AND t.id_sfet_linking = %I
                                        AND t.id_lmd_record = %I
                                        AND t.id_ls_sfe = %I;
                                  ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_ls_sfe)
                                  INTO  duplicates_count;
 
                    RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;

                    GET DIAGNOSTICS row_count = ROW_COUNT;
        
                    IF row_count <> 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''resulting_models_sfe_linkings''.', TG_NAME;
                        RETURN NULL;
                    END IF;

                    IF duplicates_count > 0 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Запись, добавляемая в таблицу ''resulting_models_sfe_linkings'', дублирует существующую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_sfe'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                ELSIF NEW.id_ls_aec_record IS NOT NULL
                THEN

                        -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_aec_record

                    /*
                    SELECT INTO duplicates_count count(*)
                    FROM imc.resulting_models_sfe_linkings t
                    WHERE t.id_sfe = NEW.id_sfe
                      AND t.id_sfet_linking = NEW.id_sfet_linking
                      AND t.id_lmd_record = NEW.id_lmd_record
                      AND t.id_ls_aec_record = NEW.id_ls_aec_record;
                    */

                    duplicates_count := 0;

                    EXECUTE format(
                                   '
                                    SELECT count(*)
                                    FROM imc.resulting_models_sfe_linkings t
                                    WHERE t.id_sfe = %I
                                        AND t.id_sfet_linking = %I
                                        AND t.id_lmd_record = %I
                                        AND t.id_ls_aec_record = %I;
                                  ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_ls_aec_record)
                                  INTO  duplicates_count;
 
                    RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;

                    GET DIAGNOSTICS row_count = ROW_COUNT;
        
                    IF row_count <> 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''resulting_models_sfe_linkings''.', TG_NAME;
                        RETURN NULL;
                    END IF;

                    IF duplicates_count > 0 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Запись, добавляемая в таблицу ''resulting_models_sfe_linkings'', дублирует существующую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                END IF;
           


            ELSIF TG_TABLE_NAME = 'models_calculations' 
            THEN
                IF NEW.calc_status IS NOT NULL AND 
                   NEW.calc_status <> 'Выполняется' AND 
                   NEW.calc_status <> 'Успешно выполнен' AND 
                   NEW.calc_status <> 'Ошибка выполнения' 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке добавления в таблицу ''models_calculations'' обнаружено недопустимое значение поля ''calc_status''.', TG_NAME;
                    RETURN NULL;
                END IF;
                

            ELSIF TG_TABLE_NAME = 'models_calculations_rules'  OR 
                  TG_TABLE_NAME = 'models_calculations_target_indicators'  OR 
                  TG_TABLE_NAME = 'models_calculations_cnf_params'            
            THEN
                UPDATE imc.models_calculations AS t
                SET t.changed = created_time, t.changed_by = NEW.changed_by
                WHERE t.id_mod_calc = NEW.id_mod_calc;

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке добавления в таблицу ''%'', ошибка при связанном обновлении таблицы ''models_calculations''.', TG_NAME, TG_TABLE_NAME;
                    RETURN NULL;
                END IF;


            ELSIF TG_TABLE_NAME = 'resulting_models_sfe_properties' 
            THEN
                IF NEW.val IS NOT NULL AND NEW.val_by_id_pvd_record IS NOT NULL
                THEN
                     RAISE EXCEPTION 'Trigger ''%'': При попытке добавления в таблицу ''resulting_models_sfe_properties'' обнаружено, что одновременно заданы не NULL поля ''val'' и ''val_by_id_pvd_record'', что недопустимо.', TG_NAME ;
                     RETURN NULL;
                END IF;


            ELSIF TG_TABLE_NAME = 'icts_sfet_linkings'
            THEN
                /*
                SELECT INTO sel_count count(*)
                FROM imc.dc_registry reg, imc.dc_records rec
                WHERE NEW.id_lmd = reg.id_lmd 
                  AND NEW.id_lmd_record = rec.id_record
                  AND NEW.id_lmd = rec.id_lmd;
                */

                sel_count := 0;

                EXECUTE format(
                    '
                    SELECT count(*)                                   
                    FROM imc.dc_registry reg, imc.dc_records rec
                    WHERE %I = reg.id_lmd 
                      AND %I = rec.id_record
                      AND %I = rec.id_lmd;

                    ', NEW.id_lmd, NEW.id_lmd_record, NEW.id_lmd)
                    INTO  sel_count;
 
                RAISE NOTICE  'Trigger ''%'': After SELECT sel_count = ''%''.', TG_NAME, sel_count;

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при поиске в словаре, указанном полем ''id_lmd'', записи, указанной полем ''id_lmd_record''.', TG_NAME;
                    RETURN NULL;
                END IF;

                IF sel_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке добавления в таблицу ''icts_sfet_linkings'' в словаре, указанном полем ''id_lmd'', не найдена запись, указанная полем ''id_lmd_record''.', TG_NAME;
                    RETURN NULL;
                END IF;


                IF NEW.id_ict_sfet = NEW.id_ls_ict_sfet
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке добавления в таблицу ''icts_sfet_linkings'' - получена некорректная запись, у которой поля ''id_ict_sfet'' и ''id_ls_ict_sfet'' заданы равными, что недопустимо.', TG_NAME ;
                    RETURN NULL;
                END IF;

                    -- Если 'Вид СФЭ'       
                IF NEW.id_ls_kind = 1
                THEN

                    IF NOT (NEW.id_ls_ict_sfe_kind IS NOT NULL AND NEW.id_ls_ict_sfet IS NULL AND NEW.id_ls_aec IS NULL AND NEW.id_ls_aec_record IS NULL)
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке добавления в таблицу ''icts_sfet_linkings'' - получена некорректная запись, у которой для вида субъекта связи ''Вид СФЭ'' задана некорректная комбинация полей ''id_ls_ict_sfe_kind'', ''id_ls_ict_sfet'', ''id_ls_aec'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                    -- Если 'Шаблон СФЭ'       
                ELSIF NEW.id_ls_kind = 2 
                THEN

                    IF NOT (NEW.id_ls_ict_sfe_kind IS NOT NULL AND NEW.id_ls_ict_sfet IS NOT NULL AND NEW.id_ls_aec IS NULL AND NEW.id_ls_aec_record IS NULL)
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'':Ошибка при попытке добавления в таблицу ''icts_sfet_linkings'' - получена некорректная запись, у которой для вида субъекта связи ''Вид СФЭ'' задана некорректная комбинация полей ''id_ls_ict_sfe_kind'', ''id_ls_ict_sfet'', ''id_ls_aec'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                    /*
                    SELECT INTO sel_count count(*)
                    FROM imc.icts_sfe_templates t
                    WHERE t.id_ict_sfet = NEW.id_ls_ict_sfet
                      AND reg.id_dc_kind = 1                 -- Тематический словарь семантик связей СФЭ друг с другом и с отличными от СФЭ сущностями
                      AND t.id_ict_sfe_kind = NEW.id_ls_ict_sfe_kind;
                      */

                    sel_count := 0;

                    EXECUTE format(
                        '
                        SELECT INTO sel_count count(*)
                        FROM imc.icts_sfe_templates t
                        WHERE t.id_ict_sfet = %I
                          AND reg.id_dc_kind = 1                 -- Тематический словарь семантик связей СФЭ друг с другом и с отличными от СФЭ сущностями
                          AND t.id_ict_sfe_kind = %I;

                        ', NEW.id_ls_ict_sfet, NEW.id_ls_ict_sfe_kind)
                        INTO  sel_count;
 
                    RAISE NOTICE  'Trigger ''%'': After SELECT sel_count = ''%''.', TG_NAME, sel_count;

                    GET DIAGNOSTICS row_count = ROW_COUNT;
        
                    IF row_count <> 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при поиске шаблона СФЭ ИРЗ, указанного полем ''id_ls_ict_sfet'', среди шаблонов вида СФЭ ИРЗ, заданных полем ''id_ls_ict_sfe_kind''.', TG_NAME;
                        RETURN NULL;
                    END IF;

                    IF sel_count < 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке добавления в таблицу ''icts_sfet_linkings'' обнаружено, что шаблон СФЭ ИРЗ, указанный полем ''id_ls_ict_sfet'', не из числа шаблонов вида СФЭ ИРЗ, заданных полем ''id_ls_ict_sfe_kind''.', TG_NAME;
                        RETURN NULL;
                    END IF;


                    -- Если 'Иная сущность'       
                ELSIF NEW.id_ls_kind = 3
                THEN

                    IF NOT (NEW.id_ls_ict_sfe_kind IS NULL AND NEW.id_ls_ict_sfet IS NULL AND NEW.id_ls_aec IS NOT NULL AND NEW.id_ls_aec_record IS NOT NULL)
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке добавления в таблицу ''icts_sfet_linkings'' - получена некорректная запись, у которой для вида субъекта связи ''Вид СФЭ'' задана некорректная комбинация полей ''id_ls_ict_sfe_kind'', ''id_ls_ict_sfet'', ''id_ls_aec'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;


                    SELECT INTO sel_count count(*)
                    FROM imc.dc_registry reg, imc.dc_records rec
                    WHERE NEW.id_ls_aec = reg.id_lmd 
                      AND reg.id_dc_kind = 3                   -- Тематический каталог отличных от СФЭ сущностей
                      AND NEW.id_ls_aec_record = rec.id_record
                      AND NEW.id_ls_aec = rec.id_lmd;

                    sel_count := 0;

                    EXECUTE format(
                        '
                        SELECT INTO sel_count count(*)
                        FROM imc.dc_registry reg, imc.dc_records rec
                        WHERE %I = reg.id_lmd 
                          AND reg.id_dc_kind = 3                   -- Тематический каталог отличных от СФЭ сущностей
                          AND %I = rec.id_record
                          AND %I = rec.id_lmd;

                        ', NEW.id_ls_aec, NEW.id_ls_aec_record, NEW.id_ls_aec)
                        INTO  sel_count;
 
                    RAISE NOTICE  'Trigger ''%'': After SELECT sel_count = ''%''.', TG_NAME, sel_count;

                    GET DIAGNOSTICS row_count = ROW_COUNT;
        
                    IF row_count <> 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при поиске иной сущности-субъекта связи шаблонов СФЭ ИРЗ, указанной полями ''id_ls_aec'' и ''id_ls_aec_record'', в соответствующем каталоге иных сущностей-субъектов связи шаблонов СФЭ ИРЗ.', TG_NAME;
                        RETURN NULL;
                    END IF;

                    IF sel_count < 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке добавления в таблицу ''icts_sfet_linkings'' обнаружено, что иная сущность-субъектов связи шаблонов СФЭ ИРЗ, указанная полями ''id_ls_aec'' и ''id_ls_aec_record'', не найдена в соответствующем каталоге иных сущностей-субъектов связи шаблонов СФЭ ИРЗ.', TG_NAME;
                        RETURN NULL;
                    END IF;

                END IF;


            ELSIF TG_TABLE_NAME = 'changing_history'
            THEN
                IF NEW.id_layer IS NOT NULL AND NEW.id_model IS NOT NULL
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке добавления в таблицу ''changing_history'' - получена некорректная запись: оба поля ''id_layer'' и ''id_model'' одновременно заданы отличными от NULL, что недопустимо.', TG_NAME ;
                    RETURN NULL;


                    -- Algoritm for cleaning table
                ELSIF NEW.id_layer IS NOT NULL AND NEW.id_model IS NULL 
                THEN

                    WITH numbered_rows AS (
                        SELECT id_sfe_property, 
                        ROW_NUMBER() OVER (ORDER BY changed DESC) as row_num,
                        COUNT(*) OVER () as total_count
                        FROM imc.changing_history
                        WHERE NEW.id_layer IS NOT NULL AND NEW.id_model IS NULL
                    )
                    DELETE FROM imc.changing_history
                    WHERE id_sfe_property IN (
                        SELECT id_sfe_property 
                        FROM numbered_rows 
                        WHERE total_count > 10000 AND row_num <= 1000
                    );
-- TODO Make success checking ????

                ELSIF NEW.id_layer IS NULL AND NEW.id_model IS NOT NULL
                THEN

                    WITH numbered_rows AS (
                        SELECT id_sfe_property, 
                        ROW_NUMBER() OVER (ORDER BY changed DESC) as row_num,
                        COUNT(*) OVER () as total_count
                        FROM imc.changing_history
                        WHERE NEW.id_layer IS NULL AND NEW.id_model IS NOT NULL
                    
                    )
                    DELETE FROM imc.changing_history
                    WHERE id_sfe_property IN (
                        SELECT id_sfe_property 
                        FROM numbered_rows 
                        WHERE total_count > 1000 AND row_num <= 100
                    );
-- TODO Make success checking ?????

                END IF;
                
            
            ELSIF TG_TABLE_NAME = 'presentations_filters'
            THEN
                IF NEW.id_layer IS NOT NULL AND NEW.id_model IS NOT NULL AND NEW.id_res_model IS NOT NULL
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке добавления в таблицу ''presentations_filters'' - получена некорректная запись: поля id_layer, id_model и id_res_model одновременно заданы отличными от NULL, что недопустимо.', TG_NAME;
                    RETURN NULL;

                    -- Algoritm for cleaning table

                ELSIF NEW.id_layer IS NOT NULL AND NEW.id_model IS NULL AND NEW.id_res_model IS NULL 
                THEN

                    WITH numbered_rows AS (
                        SELECT id_filter, 
                        ROW_NUMBER() OVER (partition by saved_by ORDER BY saved DESC) as row_num,
                        COUNT(*) OVER () as total_count
                        FROM imc.presentations_filters
                        WHERE NEW.id_layer IS NOT NULL AND NEW.id_model IS NULL AND NEW.id_res_model IS NULL
                    )
                    DELETE FROM imc.presentations_filters
                    WHERE id_filter IN (
                        SELECT id_filter 
                        FROM numbered_rows 
                        WHERE total_count > 500 AND row_num <= 10
                    );
-- TODO Make success checking ?????

                ELSIF NEW.id_layer IS NULL AND NEW.id_model IS NOT NULL AND NEW.id_res_model IS NULL
                THEN

                    WITH numbered_rows AS (
                        SELECT id_filter, 
                        ROW_NUMBER() OVER (partition by saved_by ORDER BY saved DESC) as row_num,
                        COUNT(*) OVER () as total_count
                        FROM imc.presentations_filters
                        WHERE NEW.id_layer IS NULL AND NEW.id_model IS NOT NULL AND NEW.id_res_model IS NULL
                    
                    )
                    DELETE FROM imc.presentations_filters
                    WHERE id_filter IN (
                        SELECT id_filter 
                        FROM numbered_rows 
                        WHERE total_count > 50 AND row_num <= 10
                    );
-- TODO Make success checking ????

                ELSIF NEW.id_layer IS NULL AND NEW.id_model IS NULL AND NEW.id_res_model IS NOT NULL
                THEN

                    WITH numbered_rows AS (
                        SELECT id_filter, 
                        ROW_NUMBER() OVER (partition by saved_by ORDER BY saved DESC) as row_num,
                        COUNT(*) OVER () as total_count
                        FROM imc.presentations_filters
                        WHERE NEW.id_layer IS NULL AND NEW.id_model IS NULL AND NEW.id_res_model IS NOT NULL
                    
                    )
                    DELETE FROM imc.presentations_filters
                    WHERE id_filter IN (
                        SELECT id_filter 
                        FROM numbered_rows 
                        WHERE total_count > 50 AND row_num <= 10
                    );
-- TODO Make success checking ????

                END IF;
                
            END IF;


            IF TG_NARGS > 0 
            THEN

                IF array_position(TG_ARGV, 'has_created') >= 0 
                THEN
                    NEW.created := created_time;
                END IF;

                IF array_position(TG_ARGV, 'has_changed') >= 0 
                THEN
                    NEW.changed := created_time;
                END IF;

                IF array_position(TG_ARGV, 'has_order_in_list') >= 0 
                THEN

                    BEGIN
                        EXECUTE format(
                            '
                            SELECT a.attname AS column_name
                            FROM   pg_index i
                            JOIN   pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
                            WHERE  i.indrelid = ''%I.%I''::regclass
                               AND i.indisprimary;
                            ', TG_TABLE_SCHEMA, TG_TABLE_NAME)
                            INTO  pk_column_name;

                        GET DIAGNOSTICS row_count = ROW_COUNT;
                        IF row_count <> 1 
                        THEN    
                            RAISE EXCEPTION  'Trigger ''%'': Can''t get primary key field name for table ''%'', row_count = ''%''.', TG_NAME, TG_TABLE_NAME, row_count;
                        END IF;        

                        RAISE NOTICE  'Trigger ''%'', таблица ''%'':  pk_column_name = ''%'' .', TG_TABLE_SCHEMA, TG_TABLE_NAME, pk_column_name;



                        /*    
                        RAISE NOTICE  'Trigger ''%'', содержимое таблицы ''%'':.', TG_TABLE_SCHEMA, TG_TABLE_NAME;
                        FOR _rec IN
                             EXECUTE format(
                             '
                              SELECT t.%I, t.order_in_list
                              FROM   %I.%I as t;
                            ', pk_column_name, TG_TABLE_SCHEMA, TG_TABLE_NAME)
                        LOOP
                              RAISE NOTICE  'Trigger ''%'', таблица ''%'': ''%''.', TG_TABLE_SCHEMA, TG_TABLE_NAME, _rec;
                              --RAISE NOTICE  'Trigger ''%'', таблица ''%'': ''%'', ''%''.', TG_TABLE_SCHEMA, TG_TABLE_NAME, row_to_json(_rec) ->> pk_column_name, row_to_json(_rec) ->> order_in_list;
                        END LOOP;
                        */


                        query := format( 'WITH renumbered_rows AS (
                                            SELECT 
                                                   %I, 
                                                   ROW_NUMBER() OVER (ORDER BY order_in_list) AS new_order_in_list
                                            FROM 
                                                 %I.%I
                                          )
                                          UPDATE %I.%I AS t
                                          SET order_in_list = r.new_order_in_list
                                          FROM renumbered_rows AS r
                                          WHERE t.%I = r.%I
                                         ', pk_column_name, TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_TABLE_SCHEMA, TG_TABLE_NAME, pk_column_name, pk_column_name);
                        RAISE NOTICE  'Trigger ''%'': query = ''%'' .', TG_NAME, query;


                        EXECUTE query;

                        GET DIAGNOSTICS row_count = ROW_COUNT;
                        RAISE NOTICE  'Trigger ''%'', таблица ''%'': Successfully update ''order_in_list'' field in ''%'' rows.', TG_NAME, TG_TABLE_NAME, row_count;

                    EXCEPTION
                        WHEN QUERY_CANCELED THEN
                            GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
                                                    text_var2 = PG_EXCEPTION_DETAIL,
                                                    text_var3 = PG_EXCEPTION_HINT;
                            RAISE NOTICE E'--- MESSAGE_TEXT ---\n%', text_var1;
                            RAISE NOTICE E'--- PG_EXCEPTION_DETAIL ---\n%', text_var2;
                            RAISE NOTICE E'--- PG_EXCEPTION_HINT ---\n%', text_var3;
                            GET DIAGNOSTICS stack = PG_CONTEXT;
                            RAISE NOTICE E'--- Call Stack ---\n%', stack;

                            RAISE EXCEPTION  'Trigger ''%'', таблица ''%'':   Error on update ''order_in_list'' field - Exception ''QUERY_CANCELED''.', TG_NAME, TG_TABLE_NAME;

                        WHEN ASSERT_FAILURE THEN
                            GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
                                                    text_var2 = PG_EXCEPTION_DETAIL,
                                                    text_var3 = PG_EXCEPTION_HINT;
                            RAISE NOTICE E'--- MESSAGE_TEXT ---\n%', text_var1;
                            RAISE NOTICE E'--- PG_EXCEPTION_DETAIL ---\n%', text_var2;
                            RAISE NOTICE E'--- PG_EXCEPTION_HINT ---\n%', text_var3;
                            GET DIAGNOSTICS stack = PG_CONTEXT;
                            RAISE NOTICE E'--- Call Stack ---\n%', stack;

                            RAISE EXCEPTION  'Trigger ''%'', таблица ''%'': Error on update ''order_in_list'' field - Exception ''ASSERT_FAILURE''.', TG_NAME, TG_TABLE_NAME;

                        WHEN OTHERS THEN
                            GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
                                                    text_var2 = PG_EXCEPTION_DETAIL,
                                                    text_var3 = PG_EXCEPTION_HINT;
                            RAISE NOTICE E'--- MESSAGE_TEXT ---\n%', text_var1;
                            RAISE NOTICE E'--- PG_EXCEPTION_DETAIL ---\n%', text_var2;
                            RAISE NOTICE E'--- PG_EXCEPTION_HINT ---\n%', text_var3;
                            GET DIAGNOSTICS stack = PG_CONTEXT;
                            RAISE NOTICE E'--- Call Stack ---\n%', stack;

                            RAISE EXCEPTION  'Trigger ''%'', таблица ''%'': Error on update ''order_in_list'' field - Exception ''OTHERS''.', TG_NAME, TG_TABLE_NAME;
                    END;


                    cur_max_order_in_list := 0;

                    EXECUTE format(
                                   '
                                   SELECT t.order_in_list
                                   FROM   %I.%I t
                                   ORDER BY t.order_in_list DESC 
                                   LIMIT  1
                                  ', TG_TABLE_SCHEMA, TG_TABLE_NAME)
                                  INTO  cur_max_order_in_list;

 
                    RAISE NOTICE  'Trigger ''%'': After SELECT cur_max_order_in_list = ''%''.', TG_NAME, cur_max_order_in_list;

                    GET DIAGNOSTICS row_count = ROW_COUNT;
                    IF row_count <> 1 
                    THEN    
                        cur_max_order_in_list := 0;
                        RAISE NOTICE  'Trigger ''%'': row_count <> 1, set cur_max_order_in_list to 0.', TG_NAME;
                    END IF;        

                    RAISE NOTICE  'Trigger ''%'': set new row cur_max_order_in_list to = ''%''.', TG_NAME, cur_max_order_in_list + 1;
                    NEW.order_in_list := cur_max_order_in_list + 1;
                    RAISE NOTICE  'Trigger ''%'': NEW.order_in_list = ''%''.', TG_NAME, NEW.order_in_list;

                END IF;
        
            END IF;

            RAISE NOTICE  'Trigger ''%'', таблица ''%'': Конец.', TG_NAME, TG_TABLE_NAME;

        END IF;


        RETURN NEW;
    END;
$imc_trf_universal_insert$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION imc_trf_universal_update() RETURNS trigger AS $imc_trf_universal_update$
    DECLARE
        changed_time        timestamp without time zone;
        duplicates_count    integer;
        row_count           integer;
        sel_count           integer;
    BEGIN

    	changed_time := date_trunc('second'::text, now());

        IF TG_TABLE_SCHEMA = 'imc' 
        THEN 

            RAISE NOTICE  'Trigger ''%'', таблица ''%'': Старт.', TG_NAME, TG_TABLE_NAME;

            IF TG_TABLE_NAME = 'dc_kinds'  OR 
               TG_TABLE_NAME = 'sfet_ls_kinds' OR 
               TG_TABLE_NAME = 'sfet_prop_val_types' OR 
               TG_TABLE_NAME = 'ict_cnf_param_val_types' OR  
               TG_TABLE_NAME = 'icts_calculation_rules_kinds' OR 
               TG_TABLE_NAME = 'icts_calculation_rules_allowed_operands' OR 
               TG_TABLE_NAME = 'access_objects_kinds' OR 
               TG_TABLE_NAME = 'access_objects_acts_kinds' 
            THEN
                -- RAISE EXCEPTION 'Trigger ''%'': Table ''%'' is dictionary and for read only.', TG_NAME, TG_TABLE_NAME;
                RAISE EXCEPTION 'Trigger ''%'': Таблица ''%'' является словарем и предназначена только для чтения.', TG_NAME, TG_TABLE_NAME;
                RETURN NULL;


            ELSIF TG_TABLE_NAME = 'thematic_layers'
            THEN
                INSERT INTO imc.changing_history(id_changing, id_layer, id_model, changed, changed_by) 
                VALUES (public.uuid_generate_v4(), NEW.id_layer, NULL, changed_time, NEW.changed_by);

                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE  'Trigger ''%'': row_count = ''%'' .', TG_NAME, row_count;

                IF row_count  <> 1
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка вставки записи в таблицу ''changing_history'' об изменении записи в таблицуе ''thematic_layers''.', TG_NAME;
                    RETURN NULL;
                END IF;


            ELSIF TG_TABLE_NAME = 'thematic_layers_sfes' 
            THEN
                UPDATE imc.thematic_layers AS t
                SET t.changed = changed_time, t.changed_by = NEW.changed_by
                WHERE t.id_layer = NEW.id_layer;

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблице ''%'' возникла ошибка при связанном обновлении таблицы ''thematic_layers''.', TG_NAME, TG_TABLE_NAME;
                    RETURN NULL;
                END IF;


            ELSIF TG_TABLE_NAME = 'thematic_layers_sfe_linkings'  OR 
                  TG_TABLE_NAME = 'thematic_layers_sfe_properties'
            THEN
                UPDATE imc.thematic_layers AS t
                SET t.changed = changed_time, t.changed_by = NEW.changed_by
                WHERE t.id_layer = (SELECT s.id_layer FROM imc.thematic_layers_sfes s WHERE s.id_sfe = NEW.id_sfe);

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблице ''%'' возникла ошибка при связанном обновлении таблицы ''thematic_layers''.', TG_NAME, TG_TABLE_NAME;
                    RETURN NULL;
                END IF;

                IF TG_TABLE_NAME = 'thematic_layers_sfe_properties'
                THEN

                    IF NEW.val IS NOT NULL AND NEW.val_by_id_pvd_record IS NOT NULL
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблицу ''thematic_layers_sfe_properties'' обнаружено, что одновременно заданы не NULL поля ''val'' и ''val_by_id_pvd_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;
                END IF;

                IF TG_TABLE_NAME = 'thematic_layers_sfe_linkings'
                THEN

                    IF NEW.id_ls_sfe IS NULL AND NEW.id_ls_aec_record IS NULL
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблицу ''thematic_layers_sfe_linkings'' обнаружено, что одновременно заданы как NULL поля ''id_ls_sfe'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                    IF NEW.id_ls_sfe IS NOT NULL
                    THEN
                            -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_sfe

/*                        SELECT INTO duplicates_count count(*)
                        FROM imc.thematic_layers_sfe_linkings t
                        WHERE t.id_sfe = NEW.id_sfe
                          AND t.id_sfet_linking = NEW.id_sfet_linking
                          AND t.id_lmd_record = NEW.id_lmd_record
                          AND t.id_ls_sfe = NEW.id_ls_sfe;
*/
                        duplicates_count := 0;

                        EXECUTE format(
                            '
                            SELECT count(*)
                            FROM imc.thematic_layers_sfe_linkings t
                            WHERE t.id_sfe = %I
                              AND t.id_sfet_linking = %I
                              AND t.id_lmd_record = %I
                              AND t.id_ls_sfe = %I;
                            ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_ls_sfe)
                            INTO  duplicates_count;
 
                        RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;
                        
                        GET DIAGNOSTICS row_count = ROW_COUNT;
        
                        IF row_count <> 1 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''imc.thematic_layers_sfe_linkings''.', TG_NAME;
                            RETURN NULL;
                        END IF;

                        IF duplicates_count > 0 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Запись, изменяемая в таблице ''thematic_layers_sfe_linkings'', дублирует другую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_sfe'', что недопустимо.', TG_NAME ;
                            RETURN NULL;
                        END IF;

                    ELSIF NEW.id_ls_aec_record IS NOT NULL
                    THEN

                            -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_aec_record

/*                        SELECT INTO duplicates_count count(*)
                        FROM imc.thematic_layers_sfe_linkings t
                        WHERE t.id_sfe = NEW.id_sfe
                          AND t.id_sfet_linking = NEW.id_sfet_linking
                          AND t.id_lmd_record = NEW.id_lmd_record
                          AND t.id_ls_aec_record = NEW.id_ls_aec_record;
*/
                          
                        duplicates_count := 0;

                        EXECUTE format(
                            '
                            SELECT count(*)
                            FROM imc.thematic_layers_sfe_linkings t
                            WHERE t.id_sfe = %I
                              AND t.id_sfet_linking = %I
                              AND t.id_lmd_record = %I
                              AND t.id_ls_aec_record = %I;
                            ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_ls_aec_record)
                            INTO  duplicates_count;
 
                        RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;
                        
                        GET DIAGNOSTICS row_count = ROW_COUNT;
        
                        IF row_count <> 1 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''imc.thematic_layers_sfe_linkings''.', TG_NAME;
                            RETURN NULL;
                        END IF;

                        IF duplicates_count > 0 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Запись, изменяемая в таблице ''thematic_layers_sfe_linkings'', дублирует другую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                            RETURN NULL;
                        END IF;

                    END IF;

                END IF;
    

            ELSIF TG_TABLE_NAME = 'models' 
            THEN
                INSERT INTO imc.changing_history(id_changing, id_layer, id_model, changed, changed_by) 
                VALUES (public.uuid_generate_v4(), NULL, NEW.id_model, changed_time, NEW.changed_by);

                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE  'Trigger ''%'': row_count = ''%'' .', TG_NAME, row_count;

                IF row_count  <> 1
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка вставки записи в таблицу ''changing_history'' об изменении  записи в таблице ''models''.', TG_NAME;
                    RETURN NULL;
                END IF;


            ELSIF TG_TABLE_NAME = 'models_sfe'
            THEN
                UPDATE imc.models AS t
                SET t.changed = changed_time, t.changed_by = NEW.changed_by
                WHERE t.id_model = NEW.id_model;

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблице ''%'' возникла ошибка при связанном обновлении таблицы ''models''.', TG_NAME, TG_TABLE_NAME;
                    RETURN NULL;
                END IF;


            ELSIF TG_TABLE_NAME = 'models_sfe_linkings'  OR 
                  TG_TABLE_NAME = 'models_sfe_properties' 
            THEN
                UPDATE imc.models AS t
                SET t.changed = changed_time, t.changed_by = NEW.changed_by
                WHERE t.id_model = (SELECT s.id_model FROM imc.models_sfe s WHERE s.id_sfe = NEW.id_sfe);

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке изменение записи в таблице ''%'' возникла ошибка при связанном обновлении таблицы ''models''.', TG_NAME, TG_TABLE_NAME;
                    RETURN NULL;
                END IF;

                IF TG_TABLE_NAME = 'models_sfe_properties'
                THEN
                    IF NEW.val IS NOT NULL AND NEW.val_by_id_pvd_record IS NOT NULL
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблице ''models_sfe_properties'' обнаружено, что одновременно заданы не NULL поля ''val'' и ''val_by_id_pvd_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;
                END IF;


                IF TG_TABLE_NAME = 'models_sfe_linkings'
                THEN

                    IF NEW.id_ls_sfe IS NULL AND NEW.id_ls_aec_record IS NULL
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблице ''models_sfe_linkings'' обнаружено, что одновременно заданы как NULL поля ''id_ls_sfe'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                    IF NEW.id_ls_sfe IS NOT NULL
                    THEN
                            -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_sfe

 /*                       SELECT INTO duplicates_count count(*)
                        FROM imc.models_sfe_linkings t
                        WHERE t.id_sfe = NEW.id_sfe
                          AND t.id_sfet_linking = NEW.id_sfet_linking
                          AND t.id_lmd_record = NEW.id_lmd_record
                          AND t.id_ls_sfe = NEW.id_ls_sfe;
*/
                        duplicates_count := 0;

                        EXECUTE format(
                            '
                            SELECT count(*)
                            FROM imc.models_sfe_linkings t
                            WHERE t.id_sfe = %I
                              AND t.id_sfet_linking = %I
                              AND t.id_lmd_record = %I
                              AND t.id_ls_sfe = %I;
                            ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_ls_sfe)
                            INTO  duplicates_count;
 
                        RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;
                        
                        GET DIAGNOSTICS row_count = ROW_COUNT;
        
                        IF row_count <> 1 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''imc.models_sfe_linkings''.', TG_NAME;
                            RETURN NULL;
                        END IF;

                        IF duplicates_count > 0 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Запись, изменяемая в таблице ''models_sfe_linkings'', дублирует другую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_sfe'', что недопустимо.', TG_NAME ;
                            RETURN NULL;
                        END IF;

                    ELSIF NEW.id_ls_aec_record IS NOT NULL
                    THEN

                            -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_aec_record

 /*                       SELECT INTO duplicates_count count(*)
                        FROM imc.models_sfe_linkings t
                        WHERE t.id_sfe = NEW.id_sfe
                          AND t.id_sfet_linking = NEW.id_sfet_linking
                          AND t.id_lmd_record = NEW.id_lmd_record
                          AND t.id_ls_aec_record = NEW.id_ls_aec_record;
*/
                        duplicates_count := 0;

                        EXECUTE format(
                            '
                            SELECT count(*)
                            FROM imc.models_sfe_linkings t
                            WHERE t.id_sfe = %I
                              AND t.id_sfet_linking = %I
                              AND t.id_lmd_record = %I
                              AND t.id_ls_aec_record = %I;
                            ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_ls_aec_record)
                            INTO  duplicates_count;
 
                        RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;
                        
                        GET DIAGNOSTICS row_count = ROW_COUNT;
        
                        IF row_count <> 1 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''imc.models_sfe_linkings''.', TG_NAME;
                            RETURN NULL;
                        END IF;

                        IF duplicates_count > 0 
                        THEN
                            RAISE EXCEPTION 'Trigger ''%'': Запись, изменяемая в таблице ''models_sfe_linkings'', дублирует другую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                            RETURN NULL;
                        END IF;

                    END IF;
                END IF;
            


            ELSIF TG_TABLE_NAME = 'resulting_models_sfe_linkings'
            THEN

                IF NEW.id_ls_sfe IS NULL AND NEW.id_ls_aec_record IS NULL
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблице ''resulting_models_sfe_linkings'' обнаружено, что одновременно заданы как NULL поля ''id_ls_sfe'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                    RETURN NULL;
                END IF;

                IF NEW.id_ls_sfe IS NOT NULL
                THEN
                        -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_sfe

/*                    SELECT INTO duplicates_count count(*)
                    FROM imc.resulting_models_sfe_linkings t
                    WHERE t.id_sfe = NEW.id_sfe
                      AND t.id_sfet_linking = NEW.id_sfet_linking
                      AND t.id_lmd_record = NEW.id_lmd_record
                      AND t.id_ls_sfe = NEW.id_ls_sfe;
*/
                    duplicates_count := 0;

                    EXECUTE format(
                        '
                        SELECT count(*)
                        FROM imc.resulting_models_sfe_linkings t
                        WHERE t.id_sfe = %I
                          AND t.id_sfet_linking = %I
                          AND t.id_lmd_record = %I
                          AND t.id_ls_sfe = %I;
                        ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_ls_sfe)
                        INTO  duplicates_count;
 
                    RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;
                        
                    GET DIAGNOSTICS row_count = ROW_COUNT;
        
                    IF row_count <> 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''imc.resulting_models_sfe_linkings''.', TG_NAME;
                        RETURN NULL;
                    END IF;

                    IF duplicates_count > 0 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Запись, изменяемая в таблице ''resulting_models_sfe_linkings'', дублирует существующую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_sfe'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                ELSIF NEW.id_ls_aec_record IS NOT NULL
                THEN

                        -- Проверка уникальности по id_sfe, id_sfet_linking, id_lmd_record, id_ls_aec_record

/*                    SELECT INTO duplicates_count count(*)
                    FROM imc.resulting_models_sfe_linkings t
                    WHERE t.id_sfe = NEW.id_sfe
                      AND t.id_sfet_linking = NEW.id_sfet_linking
                      AND t.id_lmd_record = NEW.id_lmd_record
                      AND t.id_ls_aec_record = NEW.id_ls_aec_record;
*/
                    duplicates_count := 0;

                    EXECUTE format(
                        '
                        SELECT count(*)
                        FROM imc.resulting_models_sfe_linkings t
                        WHERE t.id_sfe = %I
                          AND t.id_sfet_linking = %I
                          AND t.id_lmd_record = %I
                          AND t.id_ls_aec_record = %I;
                        ', NEW.id_sfe, NEW.id_sfet_linking, NEW.id_lmd_record, NEW.id_lmd_record)
                        INTO  duplicates_count;
 
                    RAISE NOTICE  'Trigger ''%'': After SELECT duplicates_count = ''%''.', TG_NAME, duplicates_count;
                        
                    GET DIAGNOSTICS row_count = ROW_COUNT;
        
                    IF row_count <> 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке проверки наличия дубликатов в таблице ''imc.resulting_models_sfe_linkings''.', TG_NAME;
                        RETURN NULL;
                    END IF;

                    IF duplicates_count > 0 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Запись, изменяемая в таблице ''resulting_models_sfe_linkings'', дублирует существующую запись по набору полей ''id_sfe'', ''id_sfet_linking'', ''id_lmd_record'', ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                END IF;
      

            ELSIF TG_TABLE_NAME = 'models_calculations' 
            THEN
                IF NEW.calc_status IS NOT NULL AND 
                   NEW.calc_status <> 'Выполняется' AND 
                   NEW.calc_status <> 'Успешно выполнен' AND 
                   NEW.calc_status <> 'Ошибка выполнения' 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'':  При попытке изменения записи в таблицe ''models_calculations'' обнаружено недопустимое значение поля ''calc_status''.', TG_NAME;
                    RETURN NULL;
                END IF;

            ELSIF TG_TABLE_NAME = 'models_calculations_rules'  OR 
                  TG_TABLE_NAME = 'models_calculations_target_indicators'  OR 
                  TG_TABLE_NAME = 'models_calculations_cnf_params'           
            THEN
                UPDATE imc.models_calculations AS t
                SET t.changed = changed_time, t.changed_by = NEW.changed_by
                WHERE t.id_mod_calc = NEW.id_mod_calc;

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблице ''%'' возникла ошибка при связанном обновлении таблицы ''models_calculations''.', TG_NAME, TG_TABLE_NAME;
                    RETURN NULL;
                END IF;


            ELSIF TG_TABLE_NAME = 'resulting_models_sfe_properties'
            THEN
                IF NEW.val IS NOT NULL AND NEW.val_by_id_pvd_record IS NOT NULL
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблицу ''resulting_models_sfe_properties'' обнаружено, что одновременно заданы не NULL поля ''val'' и ''val_by_id_pvd_record'', что недопустимо.', TG_NAME ;
                    RETURN NULL;
                END IF;
    

            ELSIF TG_TABLE_NAME = 'icts_sfet_linkings'
            THEN
  
/*                SELECT INTO sel_count count(*)
                FROM imc.dc_registry reg, imc.dc_records rec
                WHERE NEW.id_lmd = reg.id_lmd 
                  AND NEW.id_lmd_record = rec.id_record
                  AND NEW.id_lmd = rec.id_lmd;
*/

                sel_count := 0;

                EXECUTE format(
                    '
                    SELECT count(*) 
                    FROM imc.dc_registry reg, imc.dc_records rec
                    WHERE %I = reg.id_lmd 
                      AND %I = rec.id_record
                      AND %I = rec.id_lmd;

                    ', NEW.id_lmd, NEW.id_lmd_record, NEW.id_lmd)
                    INTO  sel_count;
 
                RAISE NOTICE  'Trigger ''%'': After SELECT sel_count = ''%''.', TG_NAME, sel_count;

                GET DIAGNOSTICS row_count = ROW_COUNT;
        
                IF row_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при поиске в словаре, указанном полем ''id_lmd'', записи, указанной полем ''id_lmd_record''.', TG_NAME;
                    RETURN NULL;
                END IF;

                IF sel_count <> 1 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблице ''icts_sfet_linkings'' в словаре, указанном полем ''id_lmd'', не найдена запись, указанная полем ''id_lmd_record''.', TG_NAME;
                    RETURN NULL;
                END IF;


                IF NEW.id_ict_sfet = NEW.id_ls_ict_sfet
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке изменения таблицы ''icts_sfet_linkings'' - получена некорректная запись, у которой поля ''id_ict_sfet'' и ''id_ls_ict_sfet'' заданы равными, что недопустимо.', TG_NAME ;
                    RETURN NULL;
                END IF;

                    -- Если 'Вид СФЭ'       
                IF NEW.id_ls_kind = 1
                THEN

                    IF NOT (NEW.id_ls_ict_sfe_kind IS NOT NULL AND NEW.id_ls_ict_sfet IS NULL AND NEW.id_ls_aec IS NULL AND NEW.id_ls_aec_record IS NULL)
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке изменения таблицы ''icts_sfet_linkings'' - получена некорректная запись, у которой для вида субъекта связи ''Вид СФЭ'' задана некорректная комбинация полей ''id_ls_ict_sfe_kind'', ''id_ls_ict_sfet'', ''id_ls_aec'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

                    -- Если 'Шаблон СФЭ'       
                ELSIF NEW.id_ls_kind = 2 
                THEN

                    IF NOT (NEW.id_ls_ict_sfe_kind IS NOT NULL AND NEW.id_ls_ict_sfet IS NOT NULL AND NEW.id_ls_aec IS NULL AND NEW.id_ls_aec_record IS NULL)
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке изменения таблицы ''icts_sfet_linkings'' - получена некорректная запись, у которой для вида субъекта связи ''Вид СФЭ'' задана некорректная комбинация полей ''id_ls_ict_sfe_kind'', ''id_ls_ict_sfet'', ''id_ls_aec'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;

/*                    SELECT INTO sel_count count(*)
                    FROM imc.icts_sfe_templates t
                    WHERE t.id_ict_sfet = NEW.id_ls_ict_sfet
                      AND reg.id_dc_kind = 1                 -- Тематический словарь семантик связей СФЭ друг с другом и с отличными от СФЭ сущностями
                      AND t.id_ict_sfe_kind = NEW.id_ls_ict_sfe_kind;
*/

                    sel_count := 0;

                    EXECUTE format(
                        '
                        SELECT count(*)                                   
                        FROM imc.icts_sfe_templates t
                        WHERE t.id_ict_sfet = %I
                          AND reg.id_dc_kind = 1                 -- Тематический словарь семантик связей СФЭ друг с другом и с отличными от СФЭ сущностями
                          AND t.id_ict_sfe_kind = %I;

                        ' , NEW.id_ls_ict_sfet, NEW.id_ls_ict_sfe_kind)
                        INTO  sel_count;
 
                    RAISE NOTICE  'Trigger ''%'': After SELECT sel_count = ''%''.', TG_NAME, sel_count;

                    GET DIAGNOSTICS row_count = ROW_COUNT;
        
                    IF row_count <> 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при поиске шаблона СФЭ ИРЗ, указанного полем ''id_ls_ict_sfet'', среди шаблонов вида СФЭ ИРЗ, заданного полем ''id_ls_ict_sfe_kind''.', TG_NAME;
                        RETURN NULL;
                    END IF;


                    IF sel_count < 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблице ''icts_sfet_linkings'' обнаружено, что шаблон СФЭ ИРЗ, указанный полем ''id_ls_ict_sfet'', не из числа шаблонов вида СФЭ ИРЗ, заданного полем ''id_ls_ict_sfe_kind''.', TG_NAME;
                        RETURN NULL;
                    END IF;


                    -- Если 'Иная сущность'       
                ELSIF NEW.id_ls_kind = 3
                THEN

                    IF NOT (NEW.id_ls_ict_sfe_kind IS NULL AND NEW.id_ls_ict_sfet IS NULL AND NEW.id_ls_aec IS NOT NULL AND NEW.id_ls_aec_record IS NOT NULL)
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке изменения таблицы ''icts_sfet_linkings'' - получена некорректная запись, у которой для вида субъекта связи ''Вид СФЭ'' задана некорректная комбинация полей ''id_ls_ict_sfe_kind'', ''id_ls_ict_sfet'', ''id_ls_aec'' и ''id_ls_aec_record'', что недопустимо.', TG_NAME ;
                        RETURN NULL;
                    END IF;


/*                    SELECT INTO sel_count count(*)
                    FROM imc.dc_registry reg, imc.dc_records rec
                    WHERE NEW.id_ls_aec = reg.id_lmd 
                      AND reg.id_dc_kind = 3                   -- Тематический каталог отличных от СФЭ сущностей
                      AND NEW.id_ls_aec_record = rec.id_record
                      AND NEW.id_ls_aec = rec.id_lmd;
*/

                    sel_count := 0;

                    EXECUTE format(
                        '
                        SELECT count(*)                                   
                        FROM imc.dc_registry reg, imc.dc_records rec
                        WHERE %I = reg.id_lmd 
                          AND reg.id_dc_kind = 3                   -- Тематический каталог отличных от СФЭ сущностей
                          AND %I = rec.id_record
                          AND %I = rec.id_lmd;
 
                        ', NEW.id_ls_aec, NEW.id_ls_aec_record, NEW.id_ls_aec)
                        INTO  sel_count;
 
                    RAISE NOTICE  'Trigger ''%'': After SELECT sel_count = ''%''.', TG_NAME, sel_count;

                    GET DIAGNOSTICS row_count = ROW_COUNT;
        
                    IF row_count <> 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': Ошибка при поиске иной сущности-субъекта связи шаблонов СФЭ ИРЗ, указанной полями ''id_ls_aec'' и ''id_ls_aec_record'', в соответствующем каталоге иных сущностей-субъектов связи шаблонов СФЭ ИРЗ.', TG_NAME;
                        RETURN NULL;
                    END IF;

                    IF sel_count < 1 
                    THEN
                        RAISE EXCEPTION 'Trigger ''%'': При попытке изменения записи в таблице ''icts_sfet_linkings'' обнаружено, что иная сущность-субъектов связи шаблонов СФЭ ИРЗ, указанная полями ''id_ls_aec'' и ''id_ls_aec_record'', не найдена в соответствующем каталоге иных сущностей-субъектов связи шаблонов СФЭ ИРЗ.', TG_NAME;
                        RETURN NULL;
                    END IF;

                END IF;


            ELSIF TG_TABLE_NAME = 'changing_history'
            THEN
                IF NEW.id_layer IS NOT NULL AND NEW.id_model IS NOT NULL
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке изменения таблицы ''changing_history'' - получена некорректная запись: оба поля ''id_layer'' и ''id_model'' одновременно заданы отличными от NULL, что недопустимо.', TG_NAME ;
                    RETURN NULL;


                    -- Algoritm for cleaning table
                ELSIF NEW.id_layer IS NOT NULL AND NEW.id_model IS NULL 
                THEN

                    WITH numbered_rows AS (
                        SELECT id_sfe_property, 
                        ROW_NUMBER() OVER (ORDER BY changed DESC) as row_num,
                        COUNT(*) OVER () as total_count
                        FROM imc.changing_history
                        WHERE NEW.id_layer IS NOT NULL AND NEW.id_model IS NULL
                    )
                    DELETE FROM imc.changing_history
                    WHERE id_sfe_property IN (
                        SELECT id_sfe_property 
                        FROM numbered_rows 
                        WHERE total_count > 10000 AND row_num <= 1000
                    );
-- TODO Make success checking ????


                ELSIF NEW.id_layer = NULL AND NEW.id_model IS NOT NULL
                THEN

                    WITH numbered_rows AS (
                        SELECT id_sfe_property, 
                        ROW_NUMBER() OVER (ORDER BY changed DESC) as row_num,
                        COUNT(*) OVER () as total_count
                        FROM imc.changing_history
                        WHERE NEW.id_layer IS NULL AND NEW.id_model IS NOT NULL
                    
                    )
                    DELETE FROM imc.changing_history
                    WHERE id_sfe_property IN (
                        SELECT id_sfe_property 
                        FROM numbered_rows 
                        WHERE total_count > 1000 AND row_num <= 100
                    );
-- TODO Make success checking ????

                END IF;
                
            
            ELSIF TG_TABLE_NAME = 'presentations_filters'
            THEN
                IF  NEW.id_layer IS NOT NULL AND NEW.id_model IS NOT NULL AND NEW.id_res_model IS NOT NULL
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка при попытке изменения таблицы ''presentations_filters'' - получена некорректная запись: поля id_layer, id_model и id_res_model одновременно заданы отличными от NULL, что недопустимо.', TG_NAME;
                    RETURN NULL;
                

                    -- Algoritm for cleaning table

                ELSIF NEW.id_layer IS NOT NULL AND NEW.id_model IS NULL AND NEW.id_res_model IS NULL 
                THEN

                    WITH numbered_rows AS (
                        SELECT id_filter, 
                        ROW_NUMBER() OVER (partition by saved_by ORDER BY saved DESC) as row_num,
                        COUNT(*) OVER () as total_count
                        FROM imc.presentations_filters
                        WHERE NEW.id_layer IS NOT NULL AND NEW.id_model IS NULL AND NEW.id_res_model IS NULL
                    )
                    DELETE FROM imc.presentations_filters
                    WHERE id_filter IN (
                        SELECT id_filter 
                        FROM numbered_rows 
                        WHERE total_count > 500 AND row_num <= 10
                    );
-- TODO Make success checking ????

                ELSIF NEW.id_layer IS NULL AND NEW.id_model IS NOT NULL AND NEW.id_res_model IS NULL
                THEN

                    WITH numbered_rows AS (
                        SELECT id_filter, 
                        ROW_NUMBER() OVER (partition by saved_by ORDER BY saved DESC) as row_num,
                        COUNT(*) OVER () as total_count
                        FROM imc.presentations_filters
                        WHERE NEW.id_layer IS NULL AND NEW.id_model IS NOT NULL AND NEW.id_res_model IS NULL
                    
                    )
                    DELETE FROM imc.presentations_filters
                    WHERE id_filter IN (
                        SELECT id_filter 
                        FROM numbered_rows 
                        WHERE total_count > 50 AND row_num <= 10
                    );
-- TODO Make success checking ????

                ELSIF NEW.id_layer IS NULL AND NEW.id_model IS NULL AND NEW.id_res_model IS NOT NULL
                THEN

                    WITH numbered_rows AS (
                        SELECT id_filter, 
                        ROW_NUMBER() OVER (partition by saved_by ORDER BY saved DESC) as row_num,
                        COUNT(*) OVER () as total_count
                        FROM imc.presentations_filters
                        WHERE NEW.id_layer IS NULL AND NEW.id_model IS NULL AND NEW.id_res_model IS NOT NULL
                    
                    )
                    DELETE FROM imc.presentations_filters
                    WHERE id_filter IN (
                        SELECT id_filter 
                        FROM numbered_rows 
                        WHERE total_count > 50 AND row_num <= 10
                    );
-- TODO Make success checking ????

                END IF;

            END IF;


            IF TG_NARGS > 0 
            THEN

                IF array_position(TG_ARGV, 'has_changed') >= 0 
                THEN
                    NEW.changed := changed_time;
                END IF;

                /* ------------------------------------------------------------------------------
                    ДАЕМ ВОЗМОЖНОСТЬ ОБНОВИТЬ ПОЛЕ order_in_list
                    (НАПРИМЕР, ПЕРЕУПОРЯДОЧИТЬ ЗАПИСИ ТАБЛИЦ ПЕРЕТАСКИВАНИЕМ В WEB-ИНТЕРФЕЙСЕ)
                ------------------------------------------------------------------------------------
                IF array_position(TG_ARGV, 'has_order_in_list') >= 0 
                THEN

                    -- Not allow to change order_in_list
                    NEW.order_in_list := OLD.order_in_list;
                END IF;
                */
        
            END IF;

            RAISE NOTICE  'Trigger ''%'', таблица ''%'': Конец.', TG_NAME, TG_TABLE_NAME;

        END IF;
       	
        RETURN NEW;
    END;
$imc_trf_universal_update$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION imc_trf_delete_before() RETURNS trigger AS $imc_trf_delete_before$
    DECLARE
        schemes_count  integer;
        row_count      integer;
        query          text;
    BEGIN

		IF TG_TABLE_SCHEMA = 'imc' 
        THEN 

            RAISE NOTICE  'Trigger ''%'', таблица ''%'': Старт.', TG_NAME, TG_TABLE_NAME;

			IF TG_TABLE_NAME = 'schemes' 
			THEN
                    --
                    -- Make check imc.schemes if some her model is now calculated and return NULL if TRUE
                    --

                query := format(
                    '
                    SELECT count(*)
                    FROM imc.models m
                    WHERE m.id_scheme = %I
                    AND m.now_calc_by_id_mod_calc IS NOT NULL;
                    ', OLD.id_scheme);

                query := replace(query, '"', chr(39));
                RAISE NOTICE  'Trigger ''%'': query = ''%'' .', TG_NAME, query;

                schemes_count := -1;
                EXECUTE query INTO  schemes_count;

                RAISE NOTICE  'Trigger ''%'': schemes_count = ''%'' .', TG_NAME, schemes_count;

                GET DIAGNOSTICS row_count = ROW_COUNT;
                RAISE NOTICE  'Trigger ''%'': row_count = ''%'' .', TG_NAME, row_count;

                IF schemes_count = -1 OR row_count  <> 1
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': Ошибка проверки, что ни одна из моделей удаляемой схемы с именем ''%'' не находится в процессе расчета.', TG_NAME, OLD.name;
                    RETURN NULL;
                END IF;

                IF schemes_count > 0 
                THEN
                    RAISE EXCEPTION 'Trigger ''%'': При попытке удаления записи схемы с именем ''%'' в таблице ''schemes'' обнаружено, что с ней связана или несколько моделей, которые в настоящее время обсчитываются. Поэтому данная схема не может быть удалена.', TG_NAME, OLD.name;
                    RETURN NULL;
                END IF;

    		ELSIF TG_TABLE_NAME = 'dc_kinds'  OR 
                  TG_TABLE_NAME = 'sfet_ls_kinds' OR 
                  TG_TABLE_NAME = 'sfet_prop_val_types' OR 
                  TG_TABLE_NAME = 'ict_cnf_param_val_types' OR  
                  TG_TABLE_NAME = 'icts_calculation_rules_kinds' OR 
                  TG_TABLE_NAME = 'icts_calculation_rules_allowed_operands' OR 
                  TG_TABLE_NAME = 'access_objects_kinds' OR 
                  TG_TABLE_NAME = 'access_objects_acts_kinds' 
            THEN
	            -- RAISE EXCEPTION 'Trigger ''%'': Table ''%'' is dictionary and for read only.', TG_NAME, TG_TABLE_NAME;
	            RAISE EXCEPTION 'Trigger ''%'': Таблица ''%'' является словарем и предназначена только для чтения.', TG_NAME, TG_TABLE_NAME;
	            RETURN NULL;
        	END IF;

            RAISE NOTICE  'Trigger ''%'', таблица ''%'': Конец.', TG_NAME, TG_TABLE_NAME;
		
        END IF;

        RETURN OLD;

    END;
$imc_trf_delete_before$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION imc_trf_delete_after() RETURNS trigger AS $imc_trf_delete_after$
    DECLARE
        /*deleted_order_in_list       integer;
        row_count                   integer;
        query                       text;
        pk_column_name              text;
        pk_value                    uuid;
        pk_value_text               text;
        text_var1                   text;
        text_var2                   text;
        text_var3                   text;
        stack                       text;
        _rec                        record;
        _rec1                       record;*/

    BEGIN

        IF TG_TABLE_SCHEMA = 'imc' 
        THEN 

            IF TG_NARGS > 0 
            THEN

                RAISE NOTICE  'Trigger ''%'', таблица ''%'': Старт.', TG_NAME, TG_TABLE_NAME;

                IF array_position(TG_ARGV, 'has_order_in_list') >= 0 
                THEN
/*
НИЧЕГО НЕ ДЕЛАЕМ С ТАБЛИЦЕЙ В ЧАСТИ УДАЛЕНИЯ ДЫРОК В НУМЕРАЦИИ order_in_list.
 Т.К. В ЭТОТ МОМЕНТ ВРЕМЕНИ УДАЛЯЕМАЯ ЗАПИСЬ ЕЩЕ ПРИСУТСТВУЕТ В ТАБЛИЦЕ, 
 И ПОЛУЧАЮТСЯ ДУБЛИКАТЫ ЗНАЧЕНИЙ В ПОЛЕ order_in_list И БД НЕ ДАЕТ ЭТО СДЕЛАТЬ. 
*/

                    -- deleted_order_in_list := OLD.order_in_list;
                    -- RAISE NOTICE  'Trigger ''%'': deleted_order_in_list =  ''%''.', TG_NAME, deleted_order_in_list;

                    /*
                    UPDATE TG_TABLE_NAME::text AS t
                    SET t.order_in_list = t.order_in_list - 1
                    WHERE t.order_in_list > deleted_order_in_list;

                    IF row_count <> 1 
                    THEN
                        RAISE EXCEPTION  'Trigger ''%'', таблица ''%'': Error on update ''order_in_list'' field .', TG_NAME, TG_TABLE_NAME;
                    ELSE
                        RAISE NOTICE  'Trigger ''%'', таблица ''%'': Successful update ''order_in_list'' field .', TG_NAME, TG_TABLE_NAME;
                    END IF;
                    
                    */


                    -- BEGIN
                    --     EXECUTE format(
                    --         '
                    --         SELECT a.attname AS column_name
                    --         FROM   pg_index i
                    --         JOIN   pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
                    --         WHERE  i.indrelid = ''%I.%I''::regclass
                    --            AND i.indisprimary;
                    --         ', TG_TABLE_SCHEMA, TG_TABLE_NAME)
                    --         INTO  pk_column_name;

                    --     GET DIAGNOSTICS row_count = ROW_COUNT;
                    --     IF row_count <> 1 
                    --     THEN    
                    --         RAISE EXCEPTION  'Trigger ''%'': Can''t get primary key field name for table ''%'', row_count = ''%''.', TG_NAME, TG_TABLE_NAME, row_count;
                    --     END IF;        

                    --     RAISE NOTICE  'Trigger ''%'', таблица ''%'':  pk_column_name = ''%'' .', TG_TABLE_SCHEMA, TG_TABLE_NAME, pk_column_name;

                    --     pk_value := (row_to_json(OLD) ->> pk_column_name);
                    --     --(json_column ->> 'uuid_key')::uuid
                    --     --RAISE NOTICE  'Trigger ''%'', таблица ''%'':  pk_value = ''%'' .', TG_TABLE_SCHEMA, TG_TABLE_NAME, pk_value;
                    --     RAISE NOTICE  'Trigger ''%'', таблица ''%'':  pk_value = ''%'' .', TG_TABLE_SCHEMA, TG_TABLE_NAME, row_to_json(OLD) ->> pk_column_name;
                       

                    --     pk_value_text := format( '%I', pk_value);
                    --     RAISE NOTICE  'Trigger ''%'', таблица ''%'':  pk_value_text = ''%'' .', TG_TABLE_SCHEMA, TG_TABLE_NAME, pk_value_text;


                    --     pk_value_text := replace(pk_value_text, '"', '');                        
                    --     --pk_value_text := trim(both '"' from pk_value_text);
                    --     RAISE NOTICE  'Trigger ''%'', таблица ''%'':  pk_value_text = ''%'' .', TG_TABLE_SCHEMA, TG_TABLE_NAME, pk_value_text;


                    --     RAISE NOTICE  'Trigger ''%'', таблица ''%'':.', TG_TABLE_SCHEMA, TG_TABLE_NAME;
                    --     FOR _rec IN
                    --          EXECUTE format(
                    --          '
                    --           SELECT t.%I, t.order_in_list
                    --           FROM   %I.%I as t;
                    --         ', pk_column_name, TG_TABLE_SCHEMA, TG_TABLE_NAME)
                    --     LOOP
                    --           RAISE NOTICE  'Trigger ''%'', таблица ''%'': ''%''.', TG_TABLE_SCHEMA, TG_TABLE_NAME, _rec;
                    --           --RAISE NOTICE  'Trigger ''%'', таблица ''%'': ''%'', ''%''.', TG_TABLE_SCHEMA, TG_TABLE_NAME, row_to_json(_rec) ->> pk_column_name, row_to_json(_rec) ->> order_in_list;
                    --     END LOOP;

                        

                    --     -- query := format( 'WITH renumbered_rows AS (
                    --     --                     SELECT 
                    --     --                            %I, 
                    --     --                            ROW_NUMBER() OVER (ORDER BY order_in_list) AS new_order_in_list
                    --     --                     FROM 
                    --     --                          %I.%I
                    --     --                     WHERE 
                    --     --                         %I <> %I
                    --     --                   )
                    --     --                   UPDATE %I.%I AS t
                    --     --                   SET order_in_list = r.new_order_in_list
                    --     --                   FROM renumbered_rows AS r
                    --     --                   WHERE t.%I = r.%I
                    --     --                  ', pk_column_name, TG_TABLE_SCHEMA, TG_TABLE_NAME, pk_column_name, row_to_json(OLD) ->> pk_column_name, TG_TABLE_SCHEMA, TG_TABLE_NAME, pk_column_name, pk_column_name);
                    --     -- RAISE NOTICE  'Trigger ''%'': query = ''%'' .', TG_NAME, query;

                    --     -- query := replace(query, '"', chr(39));

                    --     -- RAISE NOTICE  'Trigger ''%'': query = ''%'' .', TG_NAME, query;
                        


                    --     RAISE NOTICE  'Trigger ''%'': OLD.order_in_list = ''%'' .', TG_NAME, OLD.order_in_list;
                    --     query := format( 'WITH renumbered_rows AS (
                    --                         SELECT 
                    --                                %I, 
                    --                                ROW_NUMBER() OVER (ORDER BY order_in_list) AS new_order_in_list
                    --                         FROM 
                    --                              %I.%I
                    --                         WHERE 
                    --                             order_in_list <> %I
                    --                       )
                    --                       UPDATE %I.%I AS t
                    --                       SET order_in_list = r.new_order_in_list
                    --                       FROM renumbered_rows AS r
                    --                       WHERE t.%I = r.%I
                    --                           AND t.order_in_list <> %I
                    --                      ', pk_column_name, TG_TABLE_SCHEMA, TG_TABLE_NAME, OLD.order_in_list, TG_TABLE_SCHEMA, TG_TABLE_NAME, pk_column_name, pk_column_name, OLD.order_in_list);
                    --     query := replace(query, '"', '');
                    --     RAISE NOTICE  'Trigger ''%'': query = ''%'' .', TG_NAME, query;


                    --     EXECUTE query;

                    --     GET DIAGNOSTICS row_count = ROW_COUNT;
                    --     RAISE NOTICE  'Trigger ''%'', таблица ''%'': Successfully update ''order_in_list'' field in ''%'' rows.', TG_NAME, TG_TABLE_NAME, row_count;

                    -- EXCEPTION
                    --     WHEN QUERY_CANCELED THEN
                    --         GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
                    --                                 text_var2 = PG_EXCEPTION_DETAIL,
                    --                                 text_var3 = PG_EXCEPTION_HINT;
                    --         RAISE NOTICE E'--- MESSAGE_TEXT ---\n%', text_var1;
                    --         RAISE NOTICE E'--- PG_EXCEPTION_DETAIL ---\n%', text_var2;
                    --         RAISE NOTICE E'--- PG_EXCEPTION_HINT ---\n%', text_var3;
                    --         GET DIAGNOSTICS stack = PG_CONTEXT;
                    --         RAISE NOTICE E'--- Call Stack ---\n%', stack;

                    --         RAISE EXCEPTION  'Trigger ''%'', таблица ''%'':   Error on update ''order_in_list'' field - Exception ''QUERY_CANCELED''.', TG_NAME, TG_TABLE_NAME;

                    --     WHEN ASSERT_FAILURE THEN
                    --         GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
                    --                                 text_var2 = PG_EXCEPTION_DETAIL,
                    --                                 text_var3 = PG_EXCEPTION_HINT;
                    --         RAISE NOTICE E'--- MESSAGE_TEXT ---\n%', text_var1;
                    --         RAISE NOTICE E'--- PG_EXCEPTION_DETAIL ---\n%', text_var2;
                    --         RAISE NOTICE E'--- PG_EXCEPTION_HINT ---\n%', text_var3;
                    --         GET DIAGNOSTICS stack = PG_CONTEXT;
                    --         RAISE NOTICE E'--- Call Stack ---\n%', stack;

                    --         RAISE EXCEPTION  'Trigger ''%'', таблица ''%'': Error on update ''order_in_list'' field - Exception ''ASSERT_FAILURE''.', TG_NAME, TG_TABLE_NAME;

                    --     WHEN OTHERS THEN
                    --         GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
                    --                                 text_var2 = PG_EXCEPTION_DETAIL,
                    --                                 text_var3 = PG_EXCEPTION_HINT;
                    --         RAISE NOTICE E'--- MESSAGE_TEXT ---\n%', text_var1;
                    --         RAISE NOTICE E'--- PG_EXCEPTION_DETAIL ---\n%', text_var2;
                    --         RAISE NOTICE E'--- PG_EXCEPTION_HINT ---\n%', text_var3;
                    --         GET DIAGNOSTICS stack = PG_CONTEXT;
                    --         RAISE NOTICE E'--- Call Stack ---\n%', stack;

                    --         RAISE EXCEPTION  'Trigger ''%'', таблица ''%'': Error on update ''order_in_list'' field - Exception ''OTHERS''.', TG_NAME, TG_TABLE_NAME;
                    -- END;

                    

                END IF;
        
            END IF;

            RAISE NOTICE  'Trigger ''%'', таблица ''%'': Конец.', TG_NAME, TG_TABLE_NAME;

        END IF;


        RETURN OLD;
    END;
$imc_trf_delete_after$ LANGUAGE plpgsql;



-- CREATE TRIGGER imc_tr_*_insert BEFORE INSERT ON imc.*
--     FOR EACH ROW EXECUTE PROCEDURE imc_trf_universal_insert('has_created', 'has_changed', 'has_order_in_list');


-- CREATE TRIGGER imc_tr_*_update BEFORE UPDATE ON imc.*
--     FOR EACH ROW EXECUTE PROCEDURE imc_trf_universal_update('has_created', 'has_changed', 'has_order_in_list');


-- CREATE TRIGGER imc_tr_*_delete_before BEFORE DELETE ON imc.*
--     FOR EACH ROW EXECUTE PROCEDURE imc_trf_delete_before();


-- CREATE TRIGGER imc_tr_*_delete_after BEFORE DELETE ON imc.*
--     FOR EACH ROW EXECUTE PROCEDURE imc_trf_delete_after('has_order_in_list');







-- Таблица : Пользователи
--
-- Name: users; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 57 (номер схемы: 57)
--


CREATE TRIGGER imc_tr_users_insert BEFORE INSERT ON imc.users
    FOR EACH ROW EXECUTE PROCEDURE imc_trf_universal_insert('has_order_in_list');


CREATE TRIGGER imc_tr_users_update BEFORE UPDATE ON imc.users
    FOR EACH ROW EXECUTE PROCEDURE imc_trf_universal_update('has_order_in_list');


CREATE TRIGGER imc_tr_м_delete_before BEFORE DELETE ON imc.users
    FOR EACH ROW EXECUTE PROCEDURE imc_trf_delete_before();


CREATE TRIGGER imc_tr_users_delete_after BEFORE DELETE ON imc.users
    FOR EACH ROW EXECUTE PROCEDURE imc_trf_delete_after('has_order_in_list');




-- Таблица : Схемы
--
-- Name: schemes; Type: TABLE; Schema: imc; Owner: postgres
--
--  
--
-- стр.: 1 (номер схемы: 1)
--



CREATE TRIGGER imc_tr_schemes_insert BEFORE INSERT ON imc.schemes
    FOR EACH ROW EXECUTE PROCEDURE imc_trf_universal_insert('has_created', 'has_changed', 'has_order_in_list');


CREATE TRIGGER imc_tr_schemes_update BEFORE UPDATE ON imc.schemes
    FOR EACH ROW EXECUTE PROCEDURE imc_trf_universal_update('has_created', 'has_changed', 'has_order_in_list');


CREATE TRIGGER imc_tr_schemes_delete_before BEFORE DELETE ON imc.schemes
    FOR EACH ROW EXECUTE PROCEDURE imc_trf_delete_before();


CREATE TRIGGER imc_tr_schemes_delete_after BEFORE DELETE ON imc.schemes
    FOR EACH ROW EXECUTE PROCEDURE imc_trf_delete_after('has_order_in_list');










COMMIT;