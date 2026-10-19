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




CREATE SCHEMA IF NOT EXISTS imc;	
	
ALTER SCHEMA imc OWNER TO postgres;








-- Таблица : Пользователи
--
-- Name: users; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 57 (номер схемы: 57)
--

CREATE TABLE imc.users (
    id_user uuid UNIQUE NOT NULL,

    locked timestamp without time zone DEFAULT NULL,
    locked_by uuid DEFAULT NULL,
    unlocked timestamp without time zone DEFAULT NULL,
    unlocked_by uuid DEFAULT NULL,

    name text NOT NULL,
    aux_name text NOT NULL,
    login text NOT NULL,
    pwd_hash text NOT NULL,
    note text DEFAULT NULL,

    order_in_list integer UNIQUE NOT NULL,

    CONSTRAINT users_1 UNIQUE (name, aux_name)

);


ALTER TABLE imc.users OWNER TO postgres;

--
-- Name: users pk_users; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.users
    ADD CONSTRAINT pk_users PRIMARY KEY (id_user);

--
-- Name: users_id_user_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_users_id_user_key ON imc.users USING btree (id_user);


 
ALTER TABLE ONLY imc.users
    ADD CONSTRAINT fk_users_locked_by FOREIGN KEY (locked_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.users
    ADD CONSTRAINT fk_users_unlocked_by FOREIGN KEY (unlocked_by) REFERENCES imc.users(id_user);



--
-- Name: TABLE users; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.users IS 'Пользователи. Номер схемы: 57';


--
-- Name: COLUMN users.id_user; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.id_user IS 'Идентификатор пользователя';


--
-- Name: COLUMN users.locked; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.locked IS 'Когда заблокирован пользователь. ';

--
-- Name: COLUMN users.locked_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.locked_by IS 'Кем  заблокирован пользователь.';

--
-- Name: COLUMN users.unlocked; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.unlocked IS 'Когда разблокирован пользователь.';

--
-- Name: COLUMN users.unlocked_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.unlocked_by IS 'Кем разблокирован пользователь.';

--
-- Name: COLUMN users.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.name IS 'Название (ФИО) пользователя';

--
-- Name: COLUMN users.aux_name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.aux_name IS 'Вспомогательное название пользователя';

--
-- Name: COLUMN users.login; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.login IS 'Логин пользователя';

--
-- Name: COLUMN users.pwd_hash; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.pwd_hash IS 'Хэш пароля пользователя';

--
-- Name: COLUMN users.note; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.note IS 'Заметка о пользователе';

--
-- Name: COLUMN users.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users.order_in_list IS 'Порядковый номер (номер позиции) пользователя в списке пользователей (нужен для организации web-интерфейсов). Значение:  от 1 до N,  по триггеру INSERT';







-- Таблица : Схемы
--
-- Name: schemes; Type: TABLE; Schema: imc; Owner: postgres
--
--  
--
-- стр.: 1 (номер схемы: 1)
--

CREATE TABLE imc.schemes (
    id_scheme uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    name text UNIQUE NOT NULL DEFAULT '(не задано)',
    description text NOT NULL DEFAULT '(отсутствует)',
    order_in_list integer UNIQUE NOT NULL
);


ALTER TABLE imc.schemes OWNER TO postgres;

--
-- Name: schemes pk_schemes; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.schemes
    ADD CONSTRAINT pk_schemes PRIMARY KEY (id_scheme);

--
-- Name: schemes_id_scheme_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_imc_schemes_id_scheme_key ON imc.schemes USING btree (id_scheme);


ALTER TABLE ONLY imc.schemes
    ADD CONSTRAINT fk_schemes_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.schemes
    ADD CONSTRAINT fk_schemes_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


--
-- Name: TABLE schemes; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.schemes IS 'Схемы. Номер схемы: 1';


--
-- Name: COLUMN schemes.id_scheme; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.schemes.id_scheme IS 'Идентификатор схемы';


--
-- Name: COLUMN schemes.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.schemes.id_owner IS 'Владелец схемы (он же ее создатель)';

--
-- Name: COLUMN schemes.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.schemes.created IS 'Когда создана схема. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN schemes.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.schemes.changed IS 'Когда изменена схема. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN schemes.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.schemes.changed_by IS 'Кем изменена схема';

--
-- Name: COLUMN schemes.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.schemes.name IS 'Название схемы';

--
-- Name: COLUMN schemes.description; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.schemes.description IS 'Описание схемы';

--
-- Name: COLUMN schemes.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.schemes.order_in_list IS 'Порядковый номер (номер позиции) в списке схем (нужен для организации web-интерфейсов). Значение:	от 1 до N,  по триггеру INSERT';






-- Таблица : Группы тематических срезов
--
-- Name: thematic_layers_groups; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 2 (номер схемы: 2)
--

CREATE TABLE imc.thematic_layers_groups (
    id_group uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_scheme uuid NOT NULL,
    id_parent_group uuid NOT NULL,

    is_root_group boolean NOT NULL,
    name text NOT NULL DEFAULT '(не задано)',
    order_in_list integer NOT NULL,

    CONSTRAINT thematic_layers_groups_1 UNIQUE (id_parent_group, name),
    CONSTRAINT thematic_layers_groups_2 UNIQUE (id_parent_group, order_in_list)

    -- Switch from this to partial inique index
    -- ,
    -- CONSTRAINT thematic_layers_groups_3 UNIQUE (id_scheme, is_root_group)
);


ALTER TABLE imc.thematic_layers_groups OWNER TO postgres;

CREATE UNIQUE INDEX thematic_layers_groups_uni_idx1 ON imc.thematic_layers_groups (id_scheme) WHERE (is_root_group = TRUE);

--
-- Name: thematic_layers_groups pk_thematic_layers_groups; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.thematic_layers_groups
    ADD CONSTRAINT pk_thematic_layers_groups PRIMARY KEY (id_group);

--
-- Name: thematic_layers_groups_id_id_group_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_imc_thematic_layers_groups_id_group_key ON imc.thematic_layers_groups USING btree (id_group);


ALTER TABLE ONLY imc.thematic_layers_groups
    ADD CONSTRAINT fk_thematic_layers_groups_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.thematic_layers_groups
    ADD CONSTRAINT fk_thematic_layers_groups_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.thematic_layers_groups
    ADD CONSTRAINT fk_thematic_layers_groups_id_scheme FOREIGN KEY (id_scheme) REFERENCES imc.schemes(id_scheme);


ALTER TABLE ONLY imc.thematic_layers_groups
    ADD CONSTRAINT fk_thematic_layers_groups_id_parent_group FOREIGN KEY (id_parent_group) REFERENCES imc.thematic_layers_groups(id_group);


--
-- Name: TABLE thematic_layers_groups; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.thematic_layers_groups IS 'Группы тематических срезов. Номер схемы: 2';


--
-- Name: COLUMN thematic_layers_groups.id_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_groups.id_group IS 'Идентификатор группы тематических срезов';

--
-- Name: COLUMN thematic_layers_groups.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_groups.id_owner IS 'Владелец группы тематических срезов (он же создатель)';

--
-- Name: COLUMN thematic_layers_groups.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_groups.created IS 'Когда создана группа тематических срезов. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN thematic_layers_groups.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_groups.changed IS 'Когда изменена группа тематических срезов. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN thematic_layers_groups.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_groups.changed_by IS 'Кем изменена группа тематических срезов';


--
-- Name: COLUMN thematic_layers_groups.id_scheme; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_groups.id_scheme IS  'Идентификатор схемы, которой принадлежит группа тематических срезов';


--
-- Name: COLUMN thematic_layers_groups.id_parent_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_groups.id_parent_group IS  'Идентификатор группы-родителя для группы тематических срезов';

--
-- Name: COLUMN thematic_layers_groups.is_root_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_groups.is_root_group IS 'Является ли группа тематических срезов корнем дерева групп схемы ';

--
-- Name: COLUMN thematic_layers_groups.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_groups.name IS  'Название группы тематических срезов';

--
-- Name: COLUMN thematic_layers_groups.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_groups.order_in_list IS 'Порядковый номер (номер позиции) в списке групп, имеющих одну родительскую группу (нужен для организации web-интерфейсов). Значение:	от 1 до N,  по триггеру INSERT';





-- Таблица : Тематические срезы
--
-- Name: thematic_layers; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.:3 (номер схемы: 3)
--

CREATE TABLE imc.thematic_layers (
    id_layer uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_scheme uuid NOT NULL, 
    name text  NOT NULL DEFAULT '(не задано)',
    description text NOT NULL DEFAULT '(отсутствует)',

    CONSTRAINT thematic_layers_1 UNIQUE (id_scheme, name)

);


ALTER TABLE imc.thematic_layers OWNER TO postgres;

--
-- Name: thematic_layers pk_thematic_layers; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.thematic_layers
    ADD CONSTRAINT pk_thematic_layers PRIMARY KEY (id_layer);

--
-- Name: thematic_layers_id_layer_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_imc_thematic_layers_id_layer_key ON imc.thematic_layers USING btree (id_layer);


ALTER TABLE ONLY imc.thematic_layers
    ADD CONSTRAINT fk_thematic_layers_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);

ALTER TABLE ONLY imc.thematic_layers
    ADD CONSTRAINT fk_thematic_layers_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);

ALTER TABLE ONLY imc.thematic_layers
    ADD CONSTRAINT fk_thematic_layers_id_scheme FOREIGN KEY (id_scheme) REFERENCES imc.schemes(id_scheme);

--
-- Name: TABLE thematic_layers; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.thematic_layers IS 'Тематические срезы. Номер схемы: 3';


--
-- Name: COLUMN thematic_layers.id_layer; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers.id_layer IS 'Идентификатор тематического среза';


--
-- Name: COLUMN thematic_layers.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers.id_owner IS 'Владелец тематического среза (он же создатель)';

--
-- Name: COLUMN thematic_layers.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers.created IS 'Когда создан тематического среза. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN thematic_layers.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers.changed IS 'Когда изменен тематического среза. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN thematic_layers.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers.changed_by IS 'Кем изменен тематический срез';


--
-- Name: COLUMN thematic_layers.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers.name IS 'Название тематического среза';

--
-- Name: COLUMN thematic_layers.description; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers.description IS 'Описание тематического среза';

--
-- Name: COLUMN thematic_layers.id_scheme; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers.id_scheme IS  'Идентификатор схемы, которой принадлежит тематический срез';







-- Таблица: Вхождения тематических срезов в группы тематических срезов 
--
-- Name: thematic_layers_in_their_groups; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.:4 (номер схемы: 4)
--

CREATE TABLE imc.thematic_layers_in_their_groups (
    id_entry uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_group uuid NOT NULL,
    id_layer uuid NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT thematic_layers_in_their_groups_1 UNIQUE (id_group, id_layer),
    CONSTRAINT thematic_layers_in_their_groups_2 UNIQUE (id_group, order_in_list)

);


ALTER TABLE imc.thematic_layers_in_their_groups OWNER TO postgres;

--
-- Name: thematic_layers_in_their_groups pk_thematic_layers_in_their_groups; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.thematic_layers_in_their_groups
    ADD CONSTRAINT pk_thematic_layers_in_their_groups PRIMARY KEY (id_entry);

--
-- Name: thematic_layers_in_their_groups_id_entry_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_imc_thematic_layers_in_their_groups_id_entry_key ON imc.thematic_layers_in_their_groups USING btree (id_entry);


ALTER TABLE ONLY imc.thematic_layers_in_their_groups
    ADD CONSTRAINT fk_thematic_layers_in_their_groups_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.thematic_layers_in_their_groups
    ADD CONSTRAINT fk_thematic_layers_in_their_groups_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.thematic_layers_in_their_groups
    ADD CONSTRAINT fk_thematic_layers_in_their_groups_id_group FOREIGN KEY (id_group) REFERENCES imc.thematic_layers_groups(id_group);


ALTER TABLE ONLY imc.thematic_layers_in_their_groups
    ADD CONSTRAINT fk_thematic_layers_in_their_groups_id_layer FOREIGN KEY (id_layer) REFERENCES imc.thematic_layers(id_layer);



--
-- Name: TABLE thematic_layers_in_their_groups; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.thematic_layers_in_their_groups IS 'Вхождения тематических срезов в группы тематических срезов. Номер схемы: 4';


--
-- Name: COLUMN thematic_layers_in_their_groups.id_entry; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_in_their_groups.id_entry IS 'Идентификатор вхождения';


--
-- Name: COLUMN thematic_layers_in_their_groups.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_in_their_groups.id_owner IS 'Владелец вхождения (он же создатель)';

--
-- Name: COLUMN thematic_layers_in_their_groups.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_in_their_groups.created IS 'Когда создано вхождение. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN thematic_layers_in_their_groups.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_in_their_groups.changed IS 'Когда изменено вхождение. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN thematic_layers_in_their_groups.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_in_their_groups.changed_by IS 'Кем изменено вхождение';

--
-- Name: COLUMN thematic_layers_in_their_groups.id_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_in_their_groups.id_group IS 'Идентификатор группы тематических срезов, в которую входит тематический срез';

--
-- Name: COLUMN thematic_layers_in_their_groups.id_layer; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_in_their_groups.id_layer IS 'Идентификатор тематического среза, который входит в группу тематических срезов';

--
-- Name: COLUMN thematic_layers_in_their_groups.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_in_their_groups.order_in_list IS 'Порядковый номер (номер позиции) среза в списке срезов группы срезов (нужен для организации web-интерфейсов). Значение: от 1 до N,  по триггеру INSERT';




-- Таблица : Группы видов СФЭ
--
-- Name: sfe_kinds_groups; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.:5 (номер схемы: 5)
--

CREATE TABLE imc.sfe_kinds_groups (
    id_group uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_scheme uuid NOT NULL,
    id_parent_group uuid NOT NULL,

    is_root_group boolean  NOT NULL DEFAULT TRUE,

    name text NOT NULL DEFAULT '(не задано)',
    order_in_list integer NOT NULL,

    CONSTRAINT sfe_kinds_groups_1 UNIQUE (id_parent_group, name),
    CONSTRAINT sfe_kinds_groups_2 UNIQUE (id_parent_group, order_in_list)

    -- Switch from this to partial inique index
    -- ,
    -- CONSTRAINT sfe_kinds_groups_3 UNIQUE (id_scheme, is_root_group)

);


ALTER TABLE imc.sfe_kinds_groups OWNER TO postgres;

CREATE UNIQUE INDEX sfe_kinds_groups_uni_idx1 ON imc.sfe_kinds_groups (id_scheme) WHERE (is_root_group = TRUE);


--
-- Name: sfe_kinds_groups pk_sfe_kinds_groups; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfe_kinds_groups
    ADD CONSTRAINT pk_sfe_kinds_groups PRIMARY KEY (id_group);

--
-- Name: sfe_kinds_groups_id_group_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_imc_sfe_kinds_groups_id_group_key ON imc.sfe_kinds_groups USING btree (id_group);


ALTER TABLE ONLY imc.sfe_kinds_groups
    ADD CONSTRAINT fk_sfe_kinds_groups_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfe_kinds_groups
    ADD CONSTRAINT fk_sfe_kinds_groups_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfe_kinds_groups
    ADD CONSTRAINT fk_sfe_kinds_groups_id_scheme FOREIGN KEY (id_scheme) REFERENCES imc.schemes(id_scheme);


ALTER TABLE ONLY imc.sfe_kinds_groups
    ADD CONSTRAINT fk_sfe_kinds_groups_id_parent_group FOREIGN KEY (id_parent_group) REFERENCES imc.sfe_kinds_groups(id_group);



--
-- Name: TABLE sfe_kinds_groups; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfe_kinds_groups IS 'Группы видов СФЭ. Номер схемы: 5';

--
-- Name: COLUMN sfe_kinds_groups.id_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_groups.id_group IS 'Идентификатор группы видов СФЭ';

--
-- Name: COLUMN sfe_kinds_groups.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_groups.id_owner IS 'Владелец группы видов СФЭ. (он же создатель)';

--
-- Name: COLUMN sfe_kinds_groups.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_groups.created IS 'Когда создана группа видов СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN sfe_kinds_groups.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_groups.changed IS 'Когда изменена группа видов СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN sfe_kinds_groups.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_groups.changed_by IS 'Кем изменена группа видов СФЭ';


--
-- Name: COLUMN sfe_kinds_groups.id_scheme; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_groups.id_scheme IS  'Идентификатор схемы, которой принадлежит группы видов СФЭ';

--
-- Name: COLUMN sfe_kinds_groups.id_parent_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_groups.id_parent_group IS 'Идентификатор группы-родителя для группы видов СФЭ';

--
-- Name: COLUMN sfe_kinds_groups.is_root_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_groups.is_root_group IS 'Является ли группа видов СФЭ корнем дерева групп схемы';

--
-- Name: COLUMN sfe_kinds_groups.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_groups.name IS 'Название группы видов СФЭ';

--
-- Name: COLUMN sfe_kinds_groups.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_groups.order_in_list IS 'Порядковый номер (номер позиции) группы видов СФЭ в списке групп, имеющих одну родительскую группу (нужен для организации web-интерфейсов). Значение: от 1 до N,  по триггеру INSERT';








-- Таблица : Виды СФЭ
--
-- Name: sfe_kinds; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.:6 (номер схемы: 6)
--

CREATE TABLE imc.sfe_kinds (
    id_sfe_kind uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_scheme uuid NOT NULL,

    name text NOT NULL DEFAULT '(не задано)',

    CONSTRAINT sfe_kinds_1 UNIQUE (id_scheme, name)

);


ALTER TABLE imc.sfe_kinds OWNER TO postgres;

--
-- Name: sfe_kinds pk_sfe_kinds; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfe_kinds
    ADD CONSTRAINT pk_sfe_kinds PRIMARY KEY (id_sfe_kind);

--
-- Name: sfe_kinds_id_sfe_kind_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfe_kinds_id_sfe_kind_key ON imc.sfe_kinds USING btree (id_sfe_kind);


ALTER TABLE ONLY imc.sfe_kinds
    ADD CONSTRAINT fk_sfe_kinds_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfe_kinds
    ADD CONSTRAINT fk_sfe_kinds_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfe_kinds
    ADD CONSTRAINT fk_sfe_kinds_id_scheme FOREIGN KEY (id_scheme) REFERENCES imc.schemes(id_scheme);



--
-- Name: TABLE sfe_kinds; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfe_kinds IS 'Виды СФЭ. Номер схемы: 6';


--
-- Name: COLUMN sfe_kinds.id_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds.id_sfe_kind IS 'Идентификатор вида СФЭ';

--
-- Name: COLUMN sfe_kinds.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds.id_owner IS 'Владелец вида СФЭ (он же создатель)';

--
-- Name: COLUMN sfe_kinds.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds.created IS 'Когда создан вид СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN sfe_kinds.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds.changed IS 'Когда изменен вид СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN sfe_kinds.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds.changed_by IS 'Кем изменен вид СФЭ';

--
-- Name: COLUMN sfe_kinds.id_scheme; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds.id_scheme IS  'Идентификатор схемы, которой принадлежит вид СФЭ';

--
-- Name: COLUMN sfe_kinds.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds.name IS 'Название вида СФЭ';







-- Таблица : Вхождения видов СФЭ в группы СФЭ
--
-- Name: sfe_kinds_in_their_groups; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.:7 (номер схемы: 7)
--

CREATE TABLE imc.sfe_kinds_in_their_groups (
    id_entry uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_group uuid NOT NULL,
    id_sfe_kind uuid NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT sfe_kinds_in_their_groups_1 UNIQUE (id_group, id_sfe_kind),
    CONSTRAINT sfe_kinds_in_their_groups_2 UNIQUE (id_group, order_in_list)

);


ALTER TABLE imc.sfe_kinds_in_their_groups OWNER TO postgres;

--
-- Name: pk_sfe_kinds_in_their_groups; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfe_kinds_in_their_groups
    ADD CONSTRAINT pk_sfe_kinds_in_their_groups PRIMARY KEY (id_entry);

--
-- Name: sfe_kinds_in_their_groups_id_entry_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfe_kinds_in_their_groups_id_entry_key ON imc.sfe_kinds_in_their_groups USING btree (id_entry);


ALTER TABLE ONLY imc.sfe_kinds_in_their_groups
    ADD CONSTRAINT fk_sfe_kinds_in_their_groups_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfe_kinds_in_their_groups
    ADD CONSTRAINT fk_sfe_kinds_in_their_groups_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfe_kinds_in_their_groups
    ADD CONSTRAINT fk_sfe_kinds_in_their_groups_id_group FOREIGN KEY (id_group) REFERENCES imc.sfe_kinds_groups(id_group);


ALTER TABLE ONLY imc.sfe_kinds_in_their_groups
    ADD CONSTRAINT fk_sfe_kinds_in_their_groups_id_sfe_kind FOREIGN KEY (id_sfe_kind) REFERENCES imc.sfe_kinds(id_sfe_kind);


--
-- Name: TABLE sfe_kinds_in_their_groups; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfe_kinds_in_their_groups IS 'Вхождения видов СФЭ в группы СФЭ. Номер схемы: 7';


--
-- Name: COLUMN sfe_kinds_in_their_groups.id_entry; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_in_their_groups.id_entry IS 'Идентификатор вхождения';

--
-- Name: COLUMN sfe_kinds_in_their_groups.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_in_their_groups.id_owner IS 'Владелец вхождения (он же создатель)';

--
-- Name: COLUMN sfe_kinds_in_their_groups.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_in_their_groups.created IS 'Когда создан вхождение. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN sfe_kinds_in_their_groups.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_in_their_groups.changed IS 'Когда изменено вхождение. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN sfe_kinds_in_their_groups.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_in_their_groups.changed_by IS 'Кем изменено вхождение';

--
-- Name: COLUMN sfe_kinds_in_their_groups.id_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_in_their_groups.id_group IS 'Идентификатор группы видов СФЭ, в который входит вид СФЭ';

--
-- Name: COLUMN sfe_kinds_in_their_groups.id_sfe_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_in_their_groups.id_sfe_kind IS 'Идентификатор вида СФЭ, который входит в группу видов СФЭ';

--
-- Name: COLUMN sfe_kinds_in_their_groups.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_kinds_in_their_groups.order_in_list IS 'Порядковый номер (номер позиции) вида СФЭа в списке видов СФЭ группы видов СФЭ (нужен для организации web-интерфейсов). Значение: от 1 до N,  по триггеру INSERT';










-- Таблица: Виды словарей/каталогов: 
--
-- Name: dc_kinds; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.:8 (номер схемы: 8)
--

CREATE TABLE imc.dc_kinds (
    id_dc_kind integer UNIQUE NOT NULL,

    name_full text UNIQUE NOT NULL,
    name_short text UNIQUE NOT NULL

);


ALTER TABLE imc.dc_kinds OWNER TO postgres;

--
-- Name: dc_kinds pk_dc_kinds; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.dc_kinds
    ADD CONSTRAINT pk_dc_kinds PRIMARY KEY (id_dc_kind);

--
-- Name: dc_kinds_id_dc_kind_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_dc_kinds_id_dc_kind_key ON imc.dc_kinds USING btree (id_dc_kind);



--
-- Name: TABLE dc_kinds; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.dc_kinds IS 'Виды словарей/каталогов. Номер схемы: 8';


--
-- Name: COLUMN dc_kinds.id_dc_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_kinds.id_dc_kind IS 'Идентификатор вида словаря/каталога';


--
-- Name: COLUMN dc_kinds.name_full; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_kinds.name_full IS 'Полное название вида словаря/каталога';

--
-- Name: COLUMN dc_kinds.name_short; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_kinds.name_short IS 'Краткое название вида словаря/каталога.';





INSERT INTO imc.dc_kinds (id_dc_kind, name_full, name_short) 
VALUES (1, 'Тематический словарь семантик связей СФЭ друг с другом и с отличными от СФЭ сущностями', 'Словарь семантик связей');

INSERT INTO imc.dc_kinds (id_dc_kind, name_full, name_short) 
VALUES (2, 'Тематический словарь возможных значений свойств СФЭ', 'Словарь возможных значений');

INSERT INTO imc.dc_kinds (id_dc_kind, name_full, name_short) 
VALUES (3, 'Тематический каталог отличных от СФЭ сущностей', 'Каталог иных сущностей');










-- Таблица: Реестр словарей/каталогов
--
-- Name: dc_registry; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 9 (номер схемы: 9)
--

CREATE TABLE imc.dc_registry (
    id_dc uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_scheme uuid NOT NULL,
    id_dc_kind integer NOT NULL,

    name text NOT NULL DEFAULT '(не задано)',
    description text NOT NULL DEFAULT '(отсутствует)',

    is_allowed_to_use_in_new_sfe_templates boolean NOT NULL  DEFAULT FALSE,
    order_in_list integer NOT NULL,

    CONSTRAINT dc_registry_1 UNIQUE (id_scheme, id_dc_kind, name),
    CONSTRAINT dc_registry_2 UNIQUE (id_scheme, id_dc_kind, order_in_list)

);


ALTER TABLE imc.dc_registry OWNER TO postgres;

--
-- Name: dc_registry pk_dc_registry; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.dc_registry
    ADD CONSTRAINT pk_dc_registry PRIMARY KEY (id_dc);

--
-- Name: dc_registry_id_dc_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_dc_registry_id_dc_key ON imc.dc_registry USING btree (id_dc);


ALTER TABLE ONLY imc.dc_registry
    ADD CONSTRAINT fk_dc_registry_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.dc_registry
    ADD CONSTRAINT fk_dc_registry_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.dc_registry
    ADD CONSTRAINT fk_dc_registry_id_scheme FOREIGN KEY (id_scheme) REFERENCES imc.schemes(id_scheme);


ALTER TABLE ONLY imc.dc_registry
    ADD CONSTRAINT fk_dc_registry_id_dc_kind FOREIGN KEY (id_dc_kind) REFERENCES imc.dc_kinds(id_dc_kind);



--
-- Name: TABLE dc_registry; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.dc_registry IS 'Реестр словарей/каталогов. Номер схемы: 9';


--
-- Name: COLUMN dc_registry.id_dc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.id_dc IS 'Идентификатор словаря/каталога';


--
-- Name: COLUMN dc_registry.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.id_owner IS 'Владелец словаря/каталога (он же создатель)';

--
-- Name: COLUMN dc_registry.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.created IS 'Когда создан словарь/каталог. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN dc_registry.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.changed IS 'Когда изменен словарь/каталог. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN dc_registry.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.changed_by IS 'Кем изменен словарь/каталог';

--
-- Name: COLUMN dc_registry.id_scheme; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.id_scheme IS 'Идентификатор схемы, которой принадлежит словарь/каталог';

--
-- Name: COLUMN dc_registryid_dc_kind.; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.id_dc_kind IS 'Вид словаря/каталога';

--
-- Name: COLUMN dc_registry.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.name IS 'Название словаря/каталога';

--
-- Name: COLUMN dc_registry.description; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.description IS 'Описание словаря/каталога';

--
-- Name: COLUMN dc_registry.is_allowed_to_use_in_new_sfe_templates; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.is_allowed_to_use_in_new_sfe_templates IS 'Допустить ли словарь/каталог к использованию при создании новых шаблонов СФЭ';

--
-- Name: COLUMN dc_registry.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_registry.order_in_list IS 'Порядковый номер (номер позиции) словаря/каталога в списке словарей/каталогов одного вида внутри одной схемы (нужен для организации web-интерфейсов). Значение: от 1 до N,  по триггеру INSERT';








-- Таблица :  Записи словарей/каталогов
--
-- Name: dc_records; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.:10 (номер схемы: 10)
--

CREATE TABLE imc.dc_records (
    id_record uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_dc uuid NOT NULL,

    value text NOT NULL DEFAULT '(не задано)',
    note text NOT NULL DEFAULT '(отсутствует)',
    order_in_list integer NOT NULL,

    CONSTRAINT dc_records_1 UNIQUE (id_dc, value),
    CONSTRAINT dc_records_2 UNIQUE (id_dc, order_in_list)

);


ALTER TABLE imc.dc_records OWNER TO postgres;

--
-- Name: dc_records pk_record; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.dc_records
    ADD CONSTRAINT pk_dc_records PRIMARY KEY (id_record);

--
-- Name: dc_records_id_record_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_dc_records_id_record_key ON imc.dc_records USING btree (id_record);


ALTER TABLE ONLY imc.dc_records
    ADD CONSTRAINT fk_dc_records_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.dc_records
    ADD CONSTRAINT fk_dc_records_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.dc_records
    ADD CONSTRAINT fk_dc_records_id_dc FOREIGN KEY (id_dc) REFERENCES imc.dc_registry(id_dc);


--
-- Name: TABLE dc_records; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.dc_records IS 'Записи словарей/каталогов. Номер схемы: 10';

--
-- Name: COLUMN dc_records.id_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_records.id_record IS 'Идентификатор записи словарей/каталогов';

--
-- Name: COLUMN dc_records.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_records.id_owner IS 'Владелец записи словаря/каталога (он же создатель)';

--
-- Name: COLUMN dc_records.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_records.created IS 'Когда создана запись словаря/каталога. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN dc_records.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_records.changed IS 'Когда изменена запись словаря/каталога. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN dc_records.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_records.changed_by IS 'Кем изменена запись словаря/каталога';

--
-- Name: COLUMN dc_records.id_dc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_records.id_dc IS 'Идентификатор словаря/каталога, которому принадлежит запись';

--
-- Name: COLUMN dc_records.value; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_records.value IS 'Значение записи словарей/каталогов';

--
-- Name: COLUMN dc_records.note; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_records.note IS 'Посказка/заметка о записи словарей/каталогов';

--
-- Name: COLUMN dc_records.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.dc_records.order_in_list IS 'Порядковый номер (номер позиции) записи словаря/каталога в списке записей словаря/каталога (нужен для организации web-интерфейсов). Значение: от 1 до N,  по триггеру INSERT';






-- Таблица : Шаблоны СФЭ 
--
-- Name: sfe_templates; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 11 (номер схемы: 11)
--

CREATE TABLE imc.sfe_templates (
    id_sfet uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfe_kind uuid NOT NULL,

    version text NOT NULL DEFAULT '(не задано)',
    name text NOT NULL DEFAULT '(не задано)',
    order_in_list integer NOT NULL,

    CONSTRAINT sfe_templates_1 UNIQUE (id_sfe_kind, name, version),
    CONSTRAINT sfe_templates_2 UNIQUE (id_sfe_kind, order_in_list)

);


ALTER TABLE imc.sfe_templates OWNER TO postgres;

--
-- Name: sfe_templates pk_sfe_templates; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfe_templates
    ADD CONSTRAINT pk_sfe_templates PRIMARY KEY (id_sfet);

--
-- Name: sfe_templates_id_sfet_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfe_templates_id_sfet_key ON imc.sfe_templates USING btree (id_sfet);


ALTER TABLE ONLY imc.sfe_templates
    ADD CONSTRAINT fk_sfe_templates_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfe_templates
    ADD CONSTRAINT fk_sfe_templates_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfe_templates
    ADD CONSTRAINT fk_sfe_templates_id_sfe_kind FOREIGN KEY (id_sfe_kind) REFERENCES imc.sfe_kinds(id_sfe_kind);

--
-- Name: TABLE sfe_templates; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfe_templates IS 'Шаблоны СФЭ. Номер схемы: 11';


--
-- Name: COLUMN sfe_templates.id_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_templates.id_sfet IS 'Идентификатор шаблона СФЭ';


--
-- Name: COLUMN sfe_templates.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_templates.id_owner IS 'Владелец шаблона СФЭ (он же создатель)';

--
-- Name: COLUMN sfe_templates.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_templates.created IS 'Когда создан шаблон СФЭ Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN sfe_templates.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_templates.changed IS 'Когда изменен шаблон СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN sfe_templates.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_templates.changed_by IS 'Кем изменен шаблон СФЭ';

--
-- Name: COLUMN sfe_templates.id_sfe_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_templates.id_sfe_kind IS 'Идентификатор вида СФЭ, которому принадлежит шаблон СФЭ';

--
-- Name: COLUMN sfe_templates.version; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_templates.version IS 'Версия шаблон СФЭ';

--
-- Name: COLUMN sfe_templates.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_templates.name IS 'Название шаблона СФЭ';

--
-- Name: COLUMN sfe_templates.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfe_templates.order_in_list IS 'Порядковый номер (номер позиции) шаблона СФЭ в списке шаблонов СФЭ одного вида СФЭ (нужен для организации web-интерфейсов). Значение: от 1 до N,  по триггеру INSERT';






-- Таблица : Группы связей шаблонов СФЭ
--
-- Name: sfet_linkings_groups; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 12 (номер схемы: 12)
--

CREATE TABLE imc.sfet_linkings_groups (
    id_group uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfet uuid NOT NULL,
    id_parent_group uuid NOT NULL,

    is_root_group boolean NOT NULL DEFAULT TRUE,
    name text NOT NULL DEFAULT '(не задано)',
    order_in_list integer NOT NULL,

    CONSTRAINT sfet_linkings_groups_1 UNIQUE (id_parent_group, name),
    CONSTRAINT sfet_linkings_groups_2 UNIQUE (id_parent_group, order_in_list)

    -- Switch from this to partial inique index
    -- ,
    -- CONSTRAINT sfet_linkings_groups_3 UNIQUE (id_sfet, is_root_group)
);


ALTER TABLE imc.sfet_linkings_groups OWNER TO postgres;

CREATE UNIQUE INDEX sfet_linkings_groups_uni_idx1 ON imc.sfet_linkings_groups (id_sfet) WHERE (is_root_group = TRUE);

--
-- Name: sfet_linkings_groups pk_sfet_linkings_groups; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfet_linkings_groups
    ADD CONSTRAINT pk_sfet_linkings_groups PRIMARY KEY (id_group);

--
-- Name: sfet_linkings_groups_id_group_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfet_linkings_groups_id_group_key ON imc.sfet_linkings_groups USING btree (id_group);


ALTER TABLE ONLY imc.sfet_linkings_groups
    ADD CONSTRAINT fk_sfet_linkings_groups_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfet_linkings_groups
    ADD CONSTRAINT fk_sfet_linkings_groups_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfet_linkings_groups
    ADD CONSTRAINT fk_sfet_linkings_groups_id_sfet FOREIGN KEY (id_sfet) REFERENCES imc.sfe_templates(id_sfet);


ALTER TABLE ONLY imc.sfet_linkings_groups
    ADD CONSTRAINT fk_sfet_linkings_groups_id_parent_group FOREIGN KEY (id_parent_group) REFERENCES imc.sfet_linkings_groups(id_group);


--
-- Name: TABLE sfet_linkings_groups; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfet_linkings_groups IS 'Группы связей шаблонов СФЭ. Номер схемы: 12';


--
-- Name: COLUMN sfet_linkings_groups.id_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings_groups.id_group IS 'Идентификатор группы связей шаблонов СФЭ';


--
-- Name: COLUMN sfet_linkings_groups.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings_groups.id_owner IS 'Владелец группы связей шаблонов СФЭ (он же создатель)';

--
-- Name: COLUMN sfet_linkings_groups.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings_groups.created IS 'Когда создана группа связей шаблонов СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN sfet_linkings_groups.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings_groups.changed IS 'Когда изменена группа связей шаблонов СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN sfet_linkings_groups.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings_groups.changed_by IS 'Кем изменена группа связей шаблонов СФЭ';

--
-- Name: COLUMN sfet_linkings_groups.id_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings_groups.id_sfet IS 'Идентификатор шаблона СФЭ, которому принадлежит группа';

--
-- Name: COLUMN sfet_linkings_groups.id_parent_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings_groups.id_parent_group IS 'Идентификатор группы-родителя для группы';

--
-- Name: COLUMN sfet_linkings_groups.is_root_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings_groups.is_root_group IS 'Является ли группа корнем дерева групп связей шаблона СФЭ';

--
-- Name: COLUMN sfet_linkings_groups.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings_groups.name IS 'Название группы';

--
-- Name: COLUMN sfet_linkings_groups.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings_groups.order_in_list IS 'Порядковый номер (номер позиции) группы в списке групп, имеющих одну родительскую группу (нужен для организации web-интерфейсов). Значение: от 1 до N,  по триггеру INSERT';








-- Таблица : Группы свойств шаблонов СФЭ
--
-- Name: sfet_properties_groups; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 13 (номер схемы: 13)
--

CREATE TABLE imc.sfet_properties_groups (
    id_group uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfet uuid NOT NULL,
    id_parent_group uuid NOT NULL,

    is_root_group boolean NOT NULL DEFAULT TRUE,
    name text NOT NULL DEFAULT '(не задано)',
    order_in_list integer NOT NULL,

    CONSTRAINT sfet_properties_groups_1 UNIQUE (id_parent_group, name),
    CONSTRAINT sfet_properties_groups_2 UNIQUE (id_parent_group, order_in_list)

    -- Switch from this to partial inique index
    -- ,
    -- CONSTRAINT sfet_properties_groups_3 UNIQUE (id_sfet, is_root_group)

);


ALTER TABLE imc.sfet_properties_groups OWNER TO postgres;

CREATE UNIQUE INDEX sfet_properties_groups_uni_idx1 ON imc.sfet_properties_groups (id_sfet) WHERE (is_root_group = TRUE);

--
-- Name: sfet_properties_groups pk_sfet_properties_groups; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfet_properties_groups
    ADD CONSTRAINT pk_sfet_properties_groups PRIMARY KEY (id_group);

--
-- Name: sfet_properties_groups_id_group_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfet_properties_groups_id_group_key ON imc.sfet_properties_groups USING btree (id_group);


ALTER TABLE ONLY imc.sfet_properties_groups
    ADD CONSTRAINT fk_sfet_properties_groups_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfet_properties_groups
    ADD CONSTRAINT fk_sfet_properties_groups_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfet_properties_groups
    ADD CONSTRAINT fk_sfet_properties_groups_id_sfet FOREIGN KEY (id_sfet) REFERENCES imc.sfe_templates(id_sfet);


ALTER TABLE ONLY imc.sfet_properties_groups
    ADD CONSTRAINT fk_sfet_properties_groups_id_parent_group FOREIGN KEY (id_parent_group) REFERENCES imc.sfet_properties_groups(id_group);


--
-- Name: TABLE sfet_properties_groups; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfet_properties_groups IS 'Группы свойств шаблонов СФЭ. Номер схемы: 13';


--
-- Name: COLUMN sfet_properties_groups.id_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties_groups.id_group IS 'Идентификатор группы свойств шаблонов СФЭ';


--
-- Name: COLUMN sfet_properties_groups.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties_groups.id_owner IS 'Владелец группы свойств шаблонов СФЭ (он же создатель)';

--
-- Name: COLUMN sfet_properties_groups.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties_groups.created IS 'Когда создана группа свойств шаблонов СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN sfet_properties_groups.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties_groups.changed IS 'Когда изменена группа свойств шаблонов СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN sfet_properties_groups.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties_groups.changed_by IS 'Кем изменена группа свойств шаблонов СФЭ';

--
-- Name: COLUMN sfet_properties_groups.id_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties_groups.id_sfet IS 'Идентификатор шаблона СФЭ, которому принадлежит группа';

--
-- Name: COLUMN sfet_properties_groups.id_parent_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties_groups.id_parent_group IS 'Идентификатор группы-родителя для группы';

--
-- Name: COLUMN sfet_properties_groups.is_root_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties_groups.is_root_group IS 'Является ли группа корнем дерева групп свойств шаблона СФЭ';

--
-- Name: COLUMN sfet_properties_groups.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties_groups.name IS 'Название группы';

--
-- Name: COLUMN sfet_properties_groups.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties_groups.order_in_list IS 'Порядковый номер (номер позиции) группы в списке групп, имеющих одну родительскую группу (нужен для организации web-интерфейсов). Значение: от 1 до N,  по триггеру INSERT';






-- Таблица: Виды субъектов связи шаблонов СФЭ 
--
-- Name: sfet_ls_kinds; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.:17 (номер схемы: 17)
--

CREATE TABLE imc.sfet_ls_kinds (
    id_ls_kind integer UNIQUE NOT NULL,

    name_full text UNIQUE NOT NULL,
    name_short text UNIQUE NOT NULL

);


ALTER TABLE imc.sfet_ls_kinds OWNER TO postgres;

--
-- Name: sfet_ls_kinds pk_sfet_ls_kinds; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfet_ls_kinds
    ADD CONSTRAINT pk_sfet_ls_kinds PRIMARY KEY (id_ls_kind);

--
-- Name: sfet_ls_kinds_id_ls_kind_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfet_ls_kinds_id_ls_kind_key ON imc.sfet_ls_kinds USING btree (id_ls_kind);



--
-- Name: TABLE sfet_ls_kinds; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfet_ls_kinds IS 'Виды субъектов связи шаблонов СФЭ. Номер схемы: 17';


--
-- Name: COLUMN sfet_ls_kinds.id_ls_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_ls_kinds.id_ls_kind IS 'Идентификатор вида субъекта связи шаблонов СФЭ';


--
-- Name: COLUMN sfet_ls_kinds.name_full; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_ls_kinds.name_full IS 'Полное название вида субъекта связи шаблонов СФЭ';

--
-- Name: COLUMN sfet_ls_kinds.name_short; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_ls_kinds.name_short IS 'Краткое название вида субъекта связи шаблонов СФЭ.';





INSERT INTO imc.sfet_ls_kinds (id_ls_kind, name_full, name_short) 
VALUES (1, 'Любой СФЭ, созданный по любому шаблону СФЭ,принадлежашему заданному виду СФЭ', 'Вид СФЭ');

INSERT INTO imc.sfet_ls_kinds (id_ls_kind, name_full, name_short) 
VALUES (2, 'Любой СФЭ, созданный по заданному шаблону СФЭ', 'Шаблон СФЭ');

INSERT INTO imc.sfet_ls_kinds (id_ls_kind, name_full, name_short) 
VALUES (3, 'Отличная от СФЭ сущность, заданная записью каталога иных сущностей', 'Иная сущность');









-- Таблица : Связи шаблона СФЭ
--
-- Name: sfet_linkings; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 14 (номер схемы: 14)
--

CREATE TABLE imc.sfet_linkings (
    id_sfet_linking uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfet uuid NOT NULL,
    id_sfet_linkings_group uuid NOT NULL,
    id_lmd uuid NOT NULL,
    id_ls_kind integer NOT NULL DEFAULT 2,

    is_allowed_any_lmd_record boolean NOT NULL DEFAULT false,

    id_ls_sfe_kind uuid DEFAULT NULL, 
    id_ls_sfet uuid DEFAULT NULL,
    id_ls_aec uuid DEFAULT NULL,

    is_allowed_any_aec_record boolean NOT NULL DEFAULT false

);


ALTER TABLE imc.sfet_linkings OWNER TO postgres;

--
-- Name: sfet_linkings pk_sfet_linkings; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfet_linkings
    ADD CONSTRAINT pk_sfet_linkings PRIMARY KEY (id_sfet_linking);

--
-- Name: sfet_linkings_id_sfet_linking_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfet_linkings_id_sfet_linking_key ON imc.sfet_linkings USING btree (id_sfet_linking);


ALTER TABLE ONLY imc.sfet_linkings
    ADD CONSTRAINT fk_sfet_linkings_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfet_linkings
    ADD CONSTRAINT fk_sfet_linkings_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfet_linkings
    ADD CONSTRAINT fk_sfet_linkings_id_sfet FOREIGN KEY (id_sfet) REFERENCES imc.sfe_templates(id_sfet);


ALTER TABLE ONLY imc.sfet_linkings
    ADD CONSTRAINT fk_sfet_linkings_id_sfet_linkings_group FOREIGN KEY (id_sfet_linkings_group) REFERENCES imc.sfet_linkings_groups(id_group);
 

ALTER TABLE ONLY imc.sfet_linkings
    ADD CONSTRAINT fk_sfet_linkings_id_lmd FOREIGN KEY (id_lmd) REFERENCES imc.dc_registry(id_dc);


ALTER TABLE ONLY imc.sfet_linkings
    ADD CONSTRAINT fk_sfet_linkings_id_ls_kind FOREIGN KEY (id_ls_kind) REFERENCES imc.sfet_ls_kinds(id_ls_kind);


ALTER TABLE ONLY imc.sfet_linkings
    ADD CONSTRAINT fk_sfet_linkings_id_ls_sfe_kind FOREIGN KEY (id_ls_sfe_kind) REFERENCES imc.sfe_kinds(id_sfe_kind);


ALTER TABLE ONLY imc.sfet_linkings
    ADD CONSTRAINT fk_sfet_linkings_id_ls_sfet FOREIGN KEY (id_ls_sfet) REFERENCES imc.sfe_templates(id_sfet);


ALTER TABLE ONLY imc.sfet_linkings
    ADD CONSTRAINT fk_sfet_linkings_id_ls_aec FOREIGN KEY (id_ls_aec) REFERENCES imc.dc_registry(id_dc);


--
-- Name: TABLE sfet_linkings; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfet_linkings IS 'Связи шаблона СФЭ. Номер схемы: 14';

--
-- Name: COLUMN sfet_linkings.id_sfet_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.id_sfet_linking IS 'Идентификатор связи шаблона СФЭ';

--
-- Name: COLUMN sfet_linkings.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.id_owner IS 'Владелец связи шаблона СФЭ (он же создатель)';

--
-- Name: COLUMN sfet_linkings.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.created IS 'Когда создана связь шаблона СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN sfet_linkings.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.changed IS 'Когда изменена связь шаблона СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN sfet_linkings.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.changed_by IS 'Кем изменена связь шаблона СФЭ';

--
-- Name: COLUMN sfet_linkings.id_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.id_sfet IS 'Идентификатор шаблона СФЭ, которому принадлежит связь шаблона СФЭ';

--
-- Name: COLUMN sfet_linkings.id_sfet_linkings_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.id_sfet_linkings_group IS 'Идентификатор группы связей ШСФЭ, в которую входит связь шаблона СФЭ';

--
-- Name: COLUMN sfet_linkings.id_lmd; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.id_lmd IS 'Идентификатор словаря семантик связи шаблона СФЭ';

--
-- Name: COLUMN sfet_linkings.id_ls_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.id_ls_kind IS 'Идентификатор вида субъекта связи шаблона СФЭ';

--
-- Name: COLUMN sfet_linkings.is_allowed_any_lmd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.is_allowed_any_lmd_record IS 'Любая ли запись (семантика) из словаря семантик связи разрешена';

--
-- Name: COLUMN sfet_linkings.id_ls_sfe_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.id_ls_sfe_kind IS 'Идентификатор вида СФЭ-субъекта связи';

--
-- Name: COLUMN sfet_linkings.id_ls_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.id_ls_sfet IS 'Идентификатор шаблона СФЭ-субъекта связи';

--
-- Name: COLUMN sfet_linkings.id_ls_aec; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.id_ls_aec IS 'Идентификатор каталога иных сущностей-субъектов связи';

--
-- Name: COLUMN sfet_linkings.is_allowed_any_aec_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_linkings.is_allowed_any_aec_record IS 'Любая ли сущность из каталога иных сущностей разрешена';






-- Таблица : Разрешенные семантики связей шаблонов СФЭ
--
-- Name: sfet_allowed_lmd_records; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 15 (номер схемы: 15)
--

CREATE TABLE imc.sfet_allowed_lmd_records (
    id_record uuid UNIQUE NOT NULL,

    id_sfet_linking uuid NOT NULL,
    id_lmd_record uuid NOT NULL,

    CONSTRAINT sfet_allowed_lmd_records_1 UNIQUE (id_sfet_linking, id_lmd_record)

);


ALTER TABLE imc.sfet_allowed_lmd_records OWNER TO postgres;

--
-- Name: sfet_allowed_lmd_records pk_sfet_allowed_lmd_records; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfet_allowed_lmd_records
    ADD CONSTRAINT pk_sfet_allowed_lmd_records PRIMARY KEY (id_record);

--
-- Name: sfet_allowed_lmd_records_id_record_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfet_allowed_lmd_records_id_record_key ON imc.sfet_allowed_lmd_records USING btree (id_record);


ALTER TABLE ONLY imc.sfet_allowed_lmd_records
    ADD CONSTRAINT fk_sfet_allowed_lmd_records_id_sfet_linking FOREIGN KEY (id_sfet_linking) REFERENCES imc.sfet_linkings(id_sfet_linking);


ALTER TABLE ONLY imc.sfet_allowed_lmd_records
    ADD CONSTRAINT fk_sfet_allowed_lmd_records_id_lmd_record FOREIGN KEY (id_lmd_record) REFERENCES imc.dc_records(id_record);


--
-- Name: TABLE sfet_allowed_lmd_records; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfet_allowed_lmd_records IS 'Разрешенные семантики связей шаблонов СФЭ. Номер схемы: 15';

--
-- Name: COLUMN sfet_allowed_lmd_records.id_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_allowed_lmd_records.id_record IS 'Идентификатор записи таблицы';

--
-- Name: COLUMN sfet_allowed_lmd_records.id_sfet_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_allowed_lmd_records.id_sfet_linking IS 'Идентификатор связи шаблона СФЭ, для которой (связи) задается разрешенная семантика';

--
-- Name: COLUMN sfet_allowed_lmd_records.id_lmd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_allowed_lmd_records.id_lmd_record IS 'Идентификатор записи словаря семантик связи шаблонов СФЭ, которая (запись) содержит разрешенную семантику связи';






-- Таблица : Разрешенные для связей шаблонов СФЭ иные сущности-субъекты связи 
--
-- Name: sfet_allowed_aec_records; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 16 (номер схемы: 16)
--

CREATE TABLE imc.sfet_allowed_aec_records (
    id_record uuid UNIQUE NOT NULL,

    id_sfet_linking uuid NOT NULL,
    id_aec_record uuid NOT NULL,

    CONSTRAINT sfet_allowed_aec_records_1 UNIQUE (id_sfet_linking, id_aec_record)

);


ALTER TABLE imc.sfet_allowed_aec_records OWNER TO postgres;

--
-- Name: sfet_allowed_aec_records pk_sfet_allowed_aec_records; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfet_allowed_aec_records
    ADD CONSTRAINT pk_sfet_allowed_aec_records PRIMARY KEY (id_record);

--
-- Name: sfet_allowed_aec_records_id_record_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfet_allowed_aec_records_id_record_key ON imc.sfet_allowed_aec_records USING btree (id_record);


ALTER TABLE ONLY imc.sfet_allowed_aec_records
    ADD CONSTRAINT fk_sfet_allowed_aec_records_id_sfet_linking FOREIGN KEY (id_sfet_linking) REFERENCES imc.sfet_linkings(id_sfet_linking);


ALTER TABLE ONLY imc.sfet_allowed_aec_records
    ADD CONSTRAINT fk_sfet_allowed_aec_records_id_aec_record FOREIGN KEY (id_aec_record) REFERENCES imc.dc_records(id_record);


--
-- Name: TABLE sfet_allowed_aec_records; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfet_allowed_aec_records IS 'Разрешенные для связей связей шаблонов СФЭ иные сущности-субъекты связи. Номер схемы: 16';

--
-- Name: COLUMN sfet_allowed_aec_records.id_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_allowed_aec_records.id_record IS 'Идентификатор записи таблицы';

--
-- Name: COLUMN sfet_allowed_aec_records.id_sfet_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_allowed_aec_records.id_sfet_linking IS 'Идентификатор связи шаблона СФЭ, для которой (связи) задается разрешенная иняа сущность-субъект связи';

--
-- Name: COLUMN sfet_allowed_aec_records.id_aec_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_allowed_aec_records.id_aec_record IS 'Идентификатор записи каталога иных сущностей, которая (запись) содержит наименование иной сущности, являющейся разрешенным субъектов связи шаблона СФЭ';















-- Таблица: Типы значений свойств шаблонов СФЭ 
--
-- Name: sfet_prop_val_types; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.:18 (номер схемы: 18)
--

CREATE TABLE imc.sfet_prop_val_types (
    id_val_type integer UNIQUE NOT NULL,

    name_full text UNIQUE NOT NULL,
    name_short text UNIQUE NOT NULL 

);


ALTER TABLE imc.sfet_prop_val_types OWNER TO postgres;

--
-- Name: sfet_prop_val_types pk_sfet_prop_val_types; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfet_prop_val_types
    ADD CONSTRAINT pk_sfet_prop_val_types PRIMARY KEY (id_val_type);

--
-- Name: sfet_prop_val_types_id_val_type_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfet_prop_val_types_id_val_type_key ON imc.sfet_prop_val_types USING btree (id_val_type);



--
-- Name: TABLE sfet_prop_val_types; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfet_prop_val_types IS 'Типы значений свойств шаблонов СФЭ. Номер схемы: 18';


--
-- Name: COLUMN sfet_prop_val_types.id_val_type; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_prop_val_types.id_val_type IS 'Идентификатор типа значений свойств шаблонов СФЭ';


--
-- Name: COLUMN sfet_prop_val_types.name_full; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_prop_val_types.name_full IS 'Полное название типа значений свойств шаблонов СФЭ';

--
-- Name: COLUMN sfet_prop_val_types.name_short; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_prop_val_types.name_short IS 'Краткое название типа значений свойств шаблонов СФЭ.';





INSERT INTO imc.sfet_prop_val_types (id_val_type, name_full, name_short) 
VALUES (1, 'Строка, интерпретируемая как число', 'Число');

INSERT INTO imc.sfet_prop_val_types (id_val_type, name_full, name_short) 
VALUES (2, 'Однострочный текст', 'Текст');

INSERT INTO imc.sfet_prop_val_types (id_val_type, name_full, name_short) 
VALUES (3, 'Строка, интерпретируемая как дата/время', 'Дата/время');

INSERT INTO imc.sfet_prop_val_types (id_val_type, name_full, name_short) 
VALUES (4, 'Ссылка на идентификатор записи словаря возможных значений', 'Значение из словаря');

INSERT INTO imc.sfet_prop_val_types (id_val_type, name_full, name_short) 
VALUES (5, E'Строка, интерпретируемая как  логическое значение \x22Истина\x22 или \x22Ложь', 'Да/Нет');













-- Таблица : Свойства шаблонов СФЭ
--
-- Name: sfet_properties; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 19 (номер схемы: 19)
--

CREATE TABLE imc.sfet_properties (
    id_sfet_property uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfet uuid NOT NULL,
    id_sfet_properties_group uuid NOT NULL,

    name_rus text NOT NULL DEFAULT '(не задано)',
    name_eng text NOT NULL DEFAULT '(не задано)',

    is_not_empty boolean NOT NULL DEFAULT false,
    is_only_read boolean NOT NULL DEFAULT false,
    is_key boolean NOT NULL DEFAULT false,

    id_val_type integer NOT NULL DEFAULT 2, 
    id_pvd uuid DEFAULT NULL, 

    is_allowed_any_pvd_record boolean NOT NULL DEFAULT false,

    dv text DEFAULT NULL,
    dv_by_if_pv_record uuid DEFAULT NULL,

    CONSTRAINT sfet_properties_1 UNIQUE (id_sfet, name_rus),
    CONSTRAINT sfet_properties_2 UNIQUE (id_sfet, name_eng)

);


ALTER TABLE imc.sfet_properties OWNER TO postgres;

--
-- Name: sfet_properties pk_sfet_properties; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfet_properties
    ADD CONSTRAINT pk_sfet_properties PRIMARY KEY (id_sfet_property);

--
-- Name: sfet_properties_id_sfet_property_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfet_properties_id_sfet_property_key ON imc.sfet_properties USING btree (id_sfet_property);


ALTER TABLE ONLY imc.sfet_properties
    ADD CONSTRAINT fk_sfet_properties_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfet_properties
    ADD CONSTRAINT fk_sfet_properties_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.sfet_properties
    ADD CONSTRAINT fk_sfet_properties_id_sfet FOREIGN KEY (id_sfet) REFERENCES imc.sfe_templates(id_sfet);


ALTER TABLE ONLY imc.sfet_properties
    ADD CONSTRAINT fk_sfet_properties_id_sfet_properties_group FOREIGN KEY (id_sfet_properties_group) REFERENCES imc.sfet_properties_groups(id_group);


ALTER TABLE ONLY imc.sfet_properties
    ADD CONSTRAINT fk_sfet_properties_id_val_type FOREIGN KEY (id_val_type) REFERENCES imc.sfet_prop_val_types(id_val_type);


ALTER TABLE ONLY imc.sfet_properties
    ADD CONSTRAINT fk_sfet_properties_id_pvd FOREIGN KEY (id_pvd) REFERENCES imc.dc_registry(id_dc);


ALTER TABLE ONLY imc.sfet_properties
    ADD CONSTRAINT fk_sfet_properties_dv_by_if_pv_record FOREIGN KEY (dv_by_if_pv_record) REFERENCES imc.dc_records(id_record);


--
-- Name: TABLE sfet_properties; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfet_properties IS 'Свойства шаблонов СФЭ. Номер схемы: 19';


--
-- Name: COLUMN sfet_properties.id_sfet_property; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.id_sfet_property IS 'Идентификатор свойства шаблона СФЭ';


--
-- Name: COLUMN sfet_properties.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.id_owner IS 'Владелец свойства шаблона СФЭ (он же создатель)';

--
-- Name: COLUMN sfet_properties.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.created IS 'Когда создано свойство шаблона СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN sfet_properties.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.changed IS 'Когда изменено свойство шаблона СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN sfet_properties.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.changed_by IS 'Кем изменено свойство шаблона СФЭ';

--
-- Name: COLUMN sfet_properties.id_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.id_sfet IS 'Идентификатор шаблона СФЭ, которум принадлежит свойство шаблона СФЭ';

--
-- Name: COLUMN sfet_properties.id_sfet_properties_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.id_sfet_properties_group IS 'Идентификатор группы свойств шаблона СФЭ, в котрую входит свойство шаблона СФЭ';

--
-- Name: COLUMN sfet_properties.name_rus; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.name_rus IS 'Русское название свойства шаблона СФЭ';

--
-- Name: COLUMN sfet_properties.name_eng; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.name_eng IS 'Английское название свойства шаблона СФЭ';

--
-- Name: COLUMN sfet_properties.is_not_empty; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.is_not_empty IS 'Должно ли быть задано значение свойства шаблона СФЭ';

--
-- Name: COLUMN sfet_properties.is_only_read; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.is_only_read IS E'Должно ли быть значение свойства шаблона СФЭ быть в режиме \x22только для чтения\x22';

--
-- Name: COLUMN sfet_properties.is_key; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.is_key IS 'Является ли свойство шаблона СФЭ ключевым';

--
-- Name: COLUMN sfet_properties.id_val_type; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.id_val_type IS 'Тип значения свойства шаблона СФЭ';

--
-- Name: COLUMN sfet_properties.id_pvd; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.id_pvd IS 'Идентификатор словаря возможных значений свойства шаблона СФЭ';

--
-- Name: COLUMN sfet_properties.is_allowed_any_pvd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.is_allowed_any_pvd_record IS 'Лююбая ли запись (возможное значение) из словаря возможных значений свойства шаблона СФЭ разрешена';

--
-- Name: COLUMN sfet_properties.dv; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.dv IS 'Значение свойства шаблона СФЭ по умолчанию (оно же вмененное значение, если is_only_read == True)';

--
-- Name: COLUMN sfet_properties.dv_by_if_pv_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_properties.dv_by_if_pv_record IS 'Значение свойства шаблона СФЭ по умолчанию заданное посредством идентификатора записи возможных значений ';









-- Таблица : Разрешенные для значений свойств шаблона СФЭ записи словарей возможных значений
--
-- Name: sfet_allowed_pvd_records; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 20 (номер схемы: 20)
--

CREATE TABLE imc.sfet_allowed_pvd_records (
    id_record uuid UNIQUE NOT NULL,

    id_sfet_linking uuid NOT NULL,
    id_pvd_record uuid NOT NULL,

    CONSTRAINT sfet_allowed_pvd_records_1 UNIQUE (id_sfet_linking, id_pvd_record)

);


ALTER TABLE imc.sfet_allowed_pvd_records OWNER TO postgres;

--
-- Name: sfet_allowed_pvd_records pk_sfet_allowed_pvd_records; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.sfet_allowed_pvd_records
    ADD CONSTRAINT pk_sfet_allowed_pvd_records PRIMARY KEY (id_record);

--
-- Name: sfet_allowed_pvd_records_id_record_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_sfet_allowed_pvd_records_id_record_key ON imc.sfet_allowed_pvd_records USING btree (id_record);


ALTER TABLE ONLY imc.sfet_allowed_pvd_records
    ADD CONSTRAINT fk_sfet_allowed_pvd_records_id_sfet_linking FOREIGN KEY (id_sfet_linking) REFERENCES imc.sfet_linkings(id_sfet_linking);


ALTER TABLE ONLY imc.sfet_allowed_pvd_records
    ADD CONSTRAINT fk_sfet_allowed_pvd_records_id_pvd_record FOREIGN KEY (id_pvd_record) REFERENCES imc.dc_records(id_record);


--
-- Name: TABLE sfet_allowed_pvd_records; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.sfet_allowed_pvd_records IS 'Разрешенные для связей связей шаблонов СФЭ иные сущности-субъекты связи. Номер схемы: 20';

--
-- Name: COLUMN sfet_allowed_pvd_records.id_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_allowed_pvd_records.id_record IS 'Идентификатор записи таблицы';

--
-- Name: COLUMN sfet_allowed_pvd_records.id_sfet_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_allowed_pvd_records.id_sfet_linking IS 'Идентификатор свойства шаблона СФЭ, для которого (свойства) задается разрешенное возможное значение из словаря возможных значений';

--
-- Name: COLUMN sfet_allowed_pvd_records.id_pvd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.sfet_allowed_pvd_records.id_pvd_record IS 'Идентификатор записи словаря возможных значений, которая (запись) содержит разрешенное значение свойства СФЭ';





-- Таблица : СФЭ Тематических срезов
--
-- Name: thematic_layers_sfes; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 21 (номер схемы: 21)
--

CREATE TABLE imc.thematic_layers_sfes (
    id_sfe uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_layer uuid NOT NULL,
    id_sfet uuid NOT NULL,

    vr_code text NOT NULL DEFAULT '(не задан)',

    CONSTRAINT thematic_layers_sfes_1 UNIQUE (id_layer, vr_code)

);


ALTER TABLE imc.thematic_layers_sfes OWNER TO postgres;

--
-- Name: thematic_layers_sfes pk_thematic_layers_sfes; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.thematic_layers_sfes
    ADD CONSTRAINT pk_thematic_layers_sfes PRIMARY KEY (id_sfe);

--
-- Name: thematic_layers_sfes_id_sfe_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_thematic_layers_sfes_id_sfe_key ON imc.thematic_layers_sfes USING btree (id_sfe);


ALTER TABLE ONLY imc.thematic_layers_sfes
    ADD CONSTRAINT fk_thematic_layers_sfes_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.thematic_layers_sfes
    ADD CONSTRAINT fk_thematic_layers_sfes_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.thematic_layers_sfes
    ADD CONSTRAINT fk_thematic_layers_sfes_id_layer FOREIGN KEY (id_layer) REFERENCES imc.thematic_layers(id_layer);


ALTER TABLE ONLY imc.thematic_layers_sfes
    ADD CONSTRAINT fk_thematic_layers_sfes_id_sfet FOREIGN KEY (id_sfet) REFERENCES imc.sfe_templates(id_sfet);


--
-- Name: TABLE thematic_layers_sfes; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.thematic_layers_sfes IS 'СФЭ Тематических срезов. Номер схемы: 21';


--
-- Name: COLUMN thematic_layers_sfes.id_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfes.id_sfe IS 'Идентификатор СФЭ';

--
-- Name: COLUMN thematic_layers_sfes.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfes.id_owner IS 'Владелец СФЭ (он же создатель)';

--
-- Name: COLUMN thematic_layers_sfes.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfes.created IS 'Когда создан СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN thematic_layers_sfes.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfes.changed IS 'Когда изменен СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN thematic_layers_sfes.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfes.changed_by IS 'Кем изменен СФЭ';

--
-- Name: COLUMN thematic_layers_sfes.id_layer; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfes.id_layer IS 'Идентификатор тематического среза, которому принадлежит СФЭ';

--
-- Name: COLUMN thematic_layers_sfes.id_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfes.id_sfet IS 'Идентификатор ШСФЭ, на основе которого создан СФЭ';

--
-- Name: COLUMN thematic_layers_sfes.vr_code; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfes.vr_code IS 'Код визуального распознания СФЭ (уникален в пределах тематического среза). Задается ползователем вручную';






-- Таблица : Связи СФЭ тематических срезов
--
-- Name: thematic_layers_sfe_linkings; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 22 (номер схемы: 22)
--

CREATE TABLE imc.thematic_layers_sfe_linkings (
    id_sfe_linking uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfe uuid NOT NULL,
    id_sfet_linking uuid NOT NULL,
    id_lmd_record uuid NOT NULL,
    id_ls_sfe uuid DEFAULT NULL,
    id_ls_aec_record uuid DEFAULT NULL,

    CONSTRAINT thematic_layers_sfe_linkings_1 UNIQUE (id_sfe, id_sfet_linking, id_lmd_record, id_ls_sfe),
    CONSTRAINT thematic_layers_sfe_linkings_2 UNIQUE (id_sfe, id_sfet_linking, id_lmd_record, id_ls_aec_record)

);


ALTER TABLE imc.thematic_layers_sfe_linkings OWNER TO postgres;

--
-- Name: thematic_layers_sfe_linkings pk_thematic_layers_sfe_linkings; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.thematic_layers_sfe_linkings
    ADD CONSTRAINT pk_thematic_layers_sfe_linkings PRIMARY KEY (id_sfe_linking);

--
-- Name: thematic_layers_sfe_linkings_id_sfe_linking_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_thematic_layers_sfe_linkings_id_sfe_linking_key ON imc.thematic_layers_sfe_linkings USING btree (id_sfe_linking);


ALTER TABLE ONLY imc.thematic_layers_sfe_linkings
    ADD CONSTRAINT fk_thematic_layers_sfe_linkings_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.thematic_layers_sfe_linkings
    ADD CONSTRAINT fk_thematic_layers_sfe_linkings_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.thematic_layers_sfe_linkings
    ADD CONSTRAINT fk_thematic_layers_sfe_linkings_id_sfe FOREIGN KEY (id_sfe) REFERENCES imc.thematic_layers_sfes(id_sfe);


ALTER TABLE ONLY imc.thematic_layers_sfe_linkings
    ADD CONSTRAINT fk_thematic_layers_sfe_linkings_id_sfet_linking FOREIGN KEY (id_sfet_linking) REFERENCES imc.sfet_linkings(id_sfet_linking);


ALTER TABLE ONLY imc.thematic_layers_sfe_linkings
    ADD CONSTRAINT fk_thematic_layers_sfe_linkings_id_lmd_record FOREIGN KEY (id_lmd_record) REFERENCES imc.dc_records(id_record);


ALTER TABLE ONLY imc.thematic_layers_sfe_linkings
    ADD CONSTRAINT fk_thematic_layers_sfe_linkings_id_ls_sfe FOREIGN KEY (id_ls_sfe) REFERENCES imc.thematic_layers_sfes(id_sfe);


ALTER TABLE ONLY imc.thematic_layers_sfe_linkings
    ADD CONSTRAINT fk_thematic_layers_sfe_linkings_id_ls_aec_record FOREIGN KEY (id_ls_aec_record) REFERENCES imc.dc_records(id_record);

--
-- Name: TABLE thematic_layers_sfe_linkings; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.thematic_layers_sfe_linkings IS 'Связи СФЭ тематических срезов. Номер схемы: 22';


--
-- Name: COLUMN thematic_layers_sfe_linkings.id_sfe_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_linkings.id_sfe_linking IS 'Идентификатор связи СФЭ';


--
-- Name: COLUMN thematic_layers_sfe_linkings.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_linkings.id_owner IS 'Владелец связи СФЭ (он же создатель)';

--
-- Name: COLUMN thematic_layers_sfe_linkings.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_linkings.created IS 'Когда создана связь СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN thematic_layers_sfe_linkings.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_linkings.changed IS 'Когда изменена связь СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN thematic_layers_sfe_linkings.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_linkings.changed_by IS 'Кем изменена связь СФЭ';

--
-- Name: COLUMN thematic_layers_sfe_linkings.id_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_linkings.id_sfe IS 'Идентификатор СФЭ, которому принадлежит связь';

--
-- Name: COLUMN thematic_layers_sfe_linkings.id_sfet_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_linkings.id_sfet_linking IS 'Идентификатор связи ШСФЭ, по которой создана связь СФЭ';

--
-- Name: COLUMN thematic_layers_sfe_linkings.id_lmd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_linkings.id_lmd_record IS 'Идентификатор записи семантики связи СФЭ';

--
-- Name: COLUMN thematic_layers_sfe_linkings.id_ls_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_linkings.id_ls_sfe IS 'Идентификатор СФЭ-субъекта связи';

--
-- Name: COLUMN thematic_layers_sfe_linkings.id_ls_aec_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_linkings.id_ls_aec_record IS 'Идентификатор записи каталога иных сущностей-субъекта связи';





-- Таблица : Свойства СФЭ тематических срезов 
--
-- Name: thematic_layers_sfe_properties; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 23 (номер схемы: 23)
--

CREATE TABLE imc.thematic_layers_sfe_properties (
    id_sfe_property uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfe uuid NOT NULL,
    id_sfet_property uuid NOT NULL,
    val text  DEFAULT NULL,
    val_by_id_pvd_record uuid  DEFAULT NULL,

    CONSTRAINT thematic_layers_sfe_properties_1 UNIQUE (id_sfe, id_sfet_property)

);


ALTER TABLE imc.thematic_layers_sfe_properties OWNER TO postgres;

--
-- Name: thematic_layers_sfe_properties pk_thematic_layers_sfe_properties; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.thematic_layers_sfe_properties
    ADD CONSTRAINT pk_thematic_layers_sfe_properties PRIMARY KEY (id_sfe_property);

--
-- Name: thematic_layers_sfe_properties_id_sfe_property_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_thematic_layers_sfe_properties_id_sfe_property_key ON imc.thematic_layers_sfe_properties USING btree (id_sfe_property);


ALTER TABLE ONLY imc.thematic_layers_sfe_properties
    ADD CONSTRAINT fk_thematic_layers_sfe_properties_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.thematic_layers_sfe_properties
    ADD CONSTRAINT fk_thematic_layers_sfe_properties_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.thematic_layers_sfe_properties
    ADD CONSTRAINT fk_thematic_layers_sfe_properties_id_sfe FOREIGN KEY (id_sfe) REFERENCES imc.thematic_layers_sfes(id_sfe);


ALTER TABLE ONLY imc.thematic_layers_sfe_properties
    ADD CONSTRAINT fk_thematic_layers_sfe_properties_id_sfet_property FOREIGN KEY (id_sfet_property) REFERENCES imc.sfet_properties(id_sfet_property);


ALTER TABLE ONLY imc.thematic_layers_sfe_properties
    ADD CONSTRAINT fk_thematic_layers_sfe_properties_val_by_id_pvd_record FOREIGN KEY (val_by_id_pvd_record) REFERENCES imc.dc_records(id_record);


--
-- Name: TABLE thematic_layers_sfe_properties; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.thematic_layers_sfe_properties IS 'Свойства СФЭ тематических срезов. Номер схемы: 23';


--
-- Name: COLUMN thematic_layers_sfe_properties.id_sfe_property; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_properties.id_sfe_property IS 'Идентификатор свойства СФЭ тематических срезов';


--
-- Name: COLUMN thematic_layers_sfe_properties.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_properties.id_owner IS 'Владелец свойства СФЭ (он же создатель)';

--
-- Name: COLUMN thematic_layers_sfe_properties.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_properties.created IS 'Когда создан свойства СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN thematic_layers_sfe_properties.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_properties.changed IS 'Когда изменен свойства СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN thematic_layers_sfe_properties.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_properties.changed_by IS 'Кем изменен свойства СФЭ';

--
-- Name: COLUMN thematic_layers_sfe_properties.id_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_properties.id_sfe IS 'Идентификатор СФЭ, которому принадлежит свойство';

--
-- Name: COLUMN thematic_layers_sfe_properties.id_sfet_property; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_properties.id_sfet_property IS 'Идентификатор свойства ШСФЭ, по которму создано свойство СФЭ';

--
-- Name: COLUMN thematic_layers_sfe_properties.val; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_properties.val IS 'Значение свойства СФЭ';

--
-- Name: COLUMN thematic_layers_sfe_properties.val_by_id_pvd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.thematic_layers_sfe_properties.val_by_id_pvd_record IS 'Идентификатор записи словаря возможных значений, если значение свойства является записью из этого словаря';









-- Таблица : Реестр ИРЗ
--
-- Name: icts_registry; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 24 (номер схемы: 24)
--

CREATE TABLE imc.icts_registry (
    id_ict uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_scheme uuid NOT NULL,

    version text NOT NULL DEFAULT '(не задано)',
    author text NOT NULL DEFAULT '(не задано)',
    name text NOT NULL DEFAULT '(не задано)',
    description text NOT NULL DEFAULT '(не задано)',

    is_allowed_to_calculate boolean NOT NULL,
    is_mk_result_model boolean NOT NULL,
    is_mk_target_indicators_values boolean NOT NULL,
    is_mk_result_files boolean NOT NULL,
    is_mk_report_files boolean NOT NULL,
    is_put_result_model_into_db boolean NOT NULL,
    is_put_result_model_into_files boolean NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT icts_registry_1 UNIQUE (id_scheme, version, author, name),
    CONSTRAINT icts_registry_2 UNIQUE (id_scheme, order_in_list)


);


ALTER TABLE imc.icts_registry OWNER TO postgres;

--
-- Name: icts_registry pk_icts_registry; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_registry
    ADD CONSTRAINT pk_icts_registry PRIMARY KEY (id_ict);

--
-- Name: icts_registry_id_ict_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_registry_id_ict_key ON imc.icts_registry USING btree (id_ict);


ALTER TABLE ONLY imc.icts_registry
    ADD CONSTRAINT fk_icts_registry_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_registry
    ADD CONSTRAINT fk_icts_registry_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_registry
    ADD CONSTRAINT fk_icts_registry_id_scheme FOREIGN KEY (id_scheme) REFERENCES imc.schemes(id_scheme);


--
-- Name: TABLE icts_registry; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_registry IS 'Реестр ИРЗ. Номер схемы: 24';


--
-- Name: COLUMN icts_registry.id_ict; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.id_ict IS 'Идентификатор ИРЗ';


--
-- Name: COLUMN icts_registry.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.id_owner IS 'Владелец ИРЗ в БД (он же создатель)';

--
-- Name: COLUMN icts_registry.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.created IS 'Когда создана ИРЗ в БД. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN icts_registry.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.changed IS 'Когда изменена ИРЗ в БД. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN icts_registry.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.changed_by IS 'Кем изменена ИРЗ в БД';


--
-- Name: COLUMN icts_registry.id_scheme; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.id_scheme IS 'Идентификатор схемы, которой принадлежит ИРЗ';

--
-- Name: COLUMN icts_registry.version; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.version IS 'Версия ИРЗ';

--
-- Name: COLUMN icts_registry.author; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.author IS 'Автор ИРЗ';

--
-- Name: COLUMN icts_registry.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.name IS 'Название ИРЗ';

--
-- Name: COLUMN icts_registry.description; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.description IS 'Описание ИРЗ';

--
-- Name: COLUMN icts_registry.is_allowed_to_calculate; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.is_allowed_to_calculate IS 'Допущена ли ИРЗ к расчетам модели';

--
-- Name: COLUMN icts_registry.is_mk_result_model; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.is_mk_result_model IS 'Формирует ли ИРЗ результирующую модель';

--
-- Name: COLUMN icts_registry.is_mk_target_indicators_values; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.is_mk_target_indicators_values IS 'Формирует ли ИРЗ значения целевых показателей';

--
-- Name: COLUMN icts_registry.is_mk_result_files; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.is_mk_result_files IS 'Формирует ли ИРЗ файлы с результатом расчета';

--
-- Name: COLUMN icts_registry.is_mk_report_files; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.is_mk_report_files IS 'Формирует ли ИРЗ файлы с отчетами о расчете';

--
-- Name: COLUMN icts_registry.is_put_result_model_into_db; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.is_put_result_model_into_db IS 'Размещает ли ИРЗ результирующую модель в БД';

--
-- Name: COLUMN icts_registry.is_put_result_model_into_files; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.is_put_result_model_into_files IS 'Размещает ли ИРЗ результирующую модель в файлах с результатом расчета';

--
-- Name: COLUMN icts_registry.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_registry.order_in_list IS 'Порядковый номер (номер позиции) ИРЗ в списке ИРЗ внутри одной схемы (надо для организации web-интерфейсов)';







-- Таблица : Реестр словарей/каталогов ИРЗ
--
-- Name: icts_dc_registry; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 25 (номер схемы: 25)
--

CREATE TABLE imc.icts_dc_registry (
    id_ict_dc uuid UNIQUE NOT NULL,
    id_ict_dc_inner integer  NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_ict uuid NOT NULL,

    id_dc_kind integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    order_in_list integer NOT NULL,

    CONSTRAINT icts_dc_registry_1 UNIQUE (id_ict, id_ict_dc_inner),
    CONSTRAINT icts_dc_registry_2 UNIQUE (id_ict, id_dc_kind, name),
    CONSTRAINT icts_dc_registry_3 UNIQUE (id_ict, id_dc_kind, order_in_list)

);


ALTER TABLE imc.icts_dc_registry OWNER TO postgres;

--
-- Name: icts_dc_registry pk_icts_dc_registry; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_dc_registry
    ADD CONSTRAINT pk_icts_dc_registry PRIMARY KEY (id_ict_dc);

--
-- Name: icts_dc_registry_id_ict_dc_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_dc_registry_id_ict_dc_key ON imc.icts_dc_registry USING btree (id_ict_dc);


ALTER TABLE ONLY imc.icts_dc_registry
    ADD CONSTRAINT fk_icts_dc_registry_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_dc_registry
    ADD CONSTRAINT fk_icts_dc_registry_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_dc_registry
    ADD CONSTRAINT fk_icts_dc_registry_id_ict FOREIGN KEY (id_ict) REFERENCES imc.icts_registry(id_ict);


ALTER TABLE ONLY imc.icts_dc_registry
    ADD CONSTRAINT fk_icts_dc_registry_id_dc_kind FOREIGN KEY (id_dc_kind) REFERENCES imc.dc_kinds(id_dc_kind);


--
-- Name: TABLE icts_dc_registry; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_dc_registry IS 'Реестр словарей/каталогов ИРЗ. Номер схемы: 25';


--
-- Name: COLUMN icts_dc_registry.id_ict_dc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.id_ict_dc IS 'Идентификатор словаря/каталога ИРЗ';

--
-- Name: COLUMN icts_dc_registry.id_ict_dc_inner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.id_ict_dc_inner IS 'Идентификатор словаря/каталога внутри ИРЗ';

--
-- Name: COLUMN icts_dc_registry.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.id_owner IS 'Владелец словаря/каталога ИРЗ (он же создатель)';

--
-- Name: COLUMN icts_dc_registry.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.created IS 'Когда создан словарь/каталог ИРЗ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN icts_dc_registry.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.changed IS 'Когда изменен словарь/каталог ИРЗ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN icts_dc_registry.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.changed_by IS 'Кем изменен словарь/каталог ИРЗ';

--
-- Name: COLUMN icts_dc_registryid_ict.; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.id_ict IS 'Идентификатор ИРЗ, которой принадлежит ИРЗ';

--
-- Name: COLUMN icts_dc_registry.id_dc_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.id_dc_kind IS 'Вид словаря/каталога ИРЗ';

--
-- Name: COLUMN icts_dc_registry.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.name IS 'Название словаря/каталога ИРЗ';

--
-- Name: COLUMN icts_dc_registry.description; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.description IS 'Описание словаря/каталога ИРЗ';

--
-- Name: COLUMN icts_dc_registry.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_registry.order_in_list IS 'Порядковый номер (номер позиции) словаря/каталога ИРЗ в списке словарей/каталогов ИРЗ одного вида внутри одной ИРЗ (надо для организации web-интерфейсов)';








-- Таблица : Записи словарей/каталогов ИРЗ
--
-- Name: icts_dc_records; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 26 (номер схемы: 26)
--

CREATE TABLE imc.icts_dc_records (
    id_record uuid UNIQUE NOT NULL,
    id_record_inner integer NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_ict_dc uuid NOT NULL,

    value text NOT NULL,
    note text NOT NULL DEFAULT '(отсутствует)',
    order_in_list integer NOT NULL,

    CONSTRAINT icts_dc_record_1 UNIQUE (id_ict_dc, id_record_inner),
    CONSTRAINT icts_dc_record_2 UNIQUE (id_ict_dc, value),
    CONSTRAINT icts_dc_record_3 UNIQUE (id_ict_dc, order_in_list)

);


ALTER TABLE imc.icts_dc_records OWNER TO postgres;

--
-- Name: icts_dc_records pk_icts_dc_records; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_dc_records
    ADD CONSTRAINT pk_icts_dc_records PRIMARY KEY (id_record);

--
-- Name: icts_dc_records_id_record_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_dc_records_id_record_key ON imc.icts_dc_records USING btree (id_record);


ALTER TABLE ONLY imc.icts_dc_records
    ADD CONSTRAINT fk_icts_dc_records_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_dc_records
    ADD CONSTRAINT fk_icts_dc_records_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_dc_records
    ADD CONSTRAINT fk_icts_dc_records_id_ict_dc FOREIGN KEY (id_ict_dc) REFERENCES imc.icts_dc_registry(id_ict_dc);

--
-- Name: TABLE icts_dc_records; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_dc_records IS 'Записи словарей/каталогов ИРЗ. Номер схемы: 26';


--
-- Name: COLUMN icts_dc_records.id_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.id_record IS 'Идентификатор записи словаря/каталога ИРЗ';

--
-- Name: COLUMN icts_dc_records.id_record_inner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.id_record_inner IS 'Идентификатор записи словаря/каталога ИРЗ внутри ИРЗ';


--
-- Name: COLUMN icts_dc_records.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.id_owner IS 'Владелец записи словаря/каталога ИРЗ (он же создатель)';

--
-- Name: COLUMN icts_dc_records.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.created IS 'Когда создана запись словаря/каталога ИРЗ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN icts_dc_records.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.changed IS 'Когда изменена запись словаря/каталога ИРЗ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN icts_dc_records.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.changed_by IS 'Кем изменена запиись словаря/каталога ИРЗ';

--
-- Name: COLUMN icts_dc_records.id_record_inner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.id_record_inner IS 'Идентификатор записи словаря/каталога ИРЗ внутри ИРЗ';

--
-- Name: COLUMN icts_dc_records.id_ict_dc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.id_ict_dc IS 'Идентификатор словаря/каталога ИРЗ, которому принадлежит запись';

--
-- Name: COLUMN icts_dc_records.value; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.value IS 'Значение записи';

--
-- Name: COLUMN icts_dc_records.note; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.note IS 'Подсказка/заметка о записи';

--
-- Name: COLUMN icts_dc_records.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_dc_records.order_in_list IS 'Порядковый номер (номер позиции) записи в списке записей одного словаря/каталога ИРЗ (надо для организации web-интерфейсов)';








-- Таблица: Типы значений конфигурационных параметров ИРЗ 
--
-- Name: ict_cnf_param_val_types; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 27 (номер схемы: 27)
--

CREATE TABLE imc.ict_cnf_param_val_types (
    id_val_type integer UNIQUE NOT NULL,

    name_full text UNIQUE NOT NULL,
    name_short text UNIQUE NOT NULL 

);


ALTER TABLE imc.ict_cnf_param_val_types OWNER TO postgres;

--
-- Name: ict_cnf_param_val_types pk_ict_cnf_param_val_types; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.ict_cnf_param_val_types
    ADD CONSTRAINT pk_ict_cnf_param_val_types PRIMARY KEY (id_val_type);

--
-- Name: ict_cnf_param_val_types_id_val_type_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_ict_cnf_param_val_types_id_val_type_key ON imc.ict_cnf_param_val_types USING btree (id_val_type);



--
-- Name: TABLE ict_cnf_param_val_types; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.ict_cnf_param_val_types IS 'Типы значений конфигурационных параметров ИРЗ. Номер схемы: 27';


--
-- Name: COLUMN ict_cnf_param_val_types.id_val_type; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.ict_cnf_param_val_types.id_val_type IS 'Идентификатор типа значения';


--
-- Name: COLUMN ict_cnf_param_val_types.name_full; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.ict_cnf_param_val_types.name_full IS 'Полное название типа значения';

--
-- Name: COLUMN ict_cnf_param_val_types.name_short; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.ict_cnf_param_val_types.name_short IS 'Краткое название типа значения.';





INSERT INTO imc.ict_cnf_param_val_types (id_val_type, name_full, name_short) 
VALUES (1, 'Строка, интерпретируемая как число', 'Число');

INSERT INTO imc.ict_cnf_param_val_types (id_val_type, name_full, name_short) 
VALUES (2, 'Однострочный текст', 'Текст');

INSERT INTO imc.ict_cnf_param_val_types (id_val_type, name_full, name_short) 
VALUES (3, 'Строка, интерпретируемая как дата/время', 'Дата/Время');

INSERT INTO imc.ict_cnf_param_val_types (id_val_type, name_full, name_short) 
VALUES (4, 'Массив (набор) значений, перечисленных через точку с запятой', 'Набор значений');

INSERT INTO imc.ict_cnf_param_val_types (id_val_type, name_full, name_short) 
VALUES (5, E'Строка, интерпретируемая как логическое значение \x22Истина\x22 или \x22Ложь', 'Да/Нет');












-- Таблица : Конфигурационные параметры ИРЗ
--
-- Name: icts_cnf_params; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 28 (номер схемы: 28)
--

CREATE TABLE imc.icts_cnf_params (
    id_param uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_ict uuid NOT NULL,

    id_val_type integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    dv text NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT icts_cnf_params_1 UNIQUE (id_ict, name),
    CONSTRAINT icts_cnf_params_2 UNIQUE (id_ict, order_in_list)

);


ALTER TABLE imc.icts_cnf_params OWNER TO postgres;

--
-- Name: icts_cnf_params pk_icts_cnf_params; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_cnf_params
    ADD CONSTRAINT pk_icts_cnf_params PRIMARY KEY (id_param);

--
-- Name: icts_cnf_params_id_param_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_cnf_params_id_param_key ON imc.icts_cnf_params USING btree (id_param);


ALTER TABLE ONLY imc.icts_cnf_params
    ADD CONSTRAINT fk_icts_cnf_params_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_cnf_params
    ADD CONSTRAINT fk_icts_cnf_params_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_cnf_params
    ADD CONSTRAINT fk_icts_cnf_params_id_ict FOREIGN KEY (id_ict) REFERENCES imc.icts_registry(id_ict);


ALTER TABLE ONLY imc.icts_cnf_params
    ADD CONSTRAINT fk_icts_cnf_params_id_val_type FOREIGN KEY (id_val_type) REFERENCES imc.ict_cnf_param_val_types(id_val_type);


--
-- Name: TABLE icts_cnf_params; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_cnf_params IS 'Конфигурационные параметры ИРЗ. Номер схемы: 28';


--
-- Name: COLUMN icts_cnf_params.id_param; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.id_param IS 'Идентификатор параметра';


--
-- Name: COLUMN icts_cnf_params.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.id_owner IS 'Владелец параметра (он же создатель)';

--
-- Name: COLUMN icts_cnf_params.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.created IS 'Когда создан параметр. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN icts_cnf_params.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.changed IS 'Когда изменен параметр. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN icts_cnf_params.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.changed_by IS 'Кем изменен параметр';

--
-- Name: COLUMN icts_cnf_params.id_ict; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.id_ict IS 'Идентификатор ИРЗ, которй принадлежит параметр';

--
-- Name: COLUMN icts_cnf_params.id_val_type; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.id_val_type IS 'Тип значения параметра';

--
-- Name: COLUMN icts_cnf_params.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.name IS 'Название параметра';

--
-- Name: COLUMN icts_cnf_params.description; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.description IS 'Описание параметра';

--
-- Name: COLUMN icts_cnf_params.dv; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.dv IS 'Значение параметра по умолчанию';

--
-- Name: COLUMN icts_cnf_params.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_cnf_params.order_in_list IS 'Порядковый номер (номер позиции) параметра в списке параметров одной ИРЗ (надо для организации web-интерфейсов)';





-- Таблица :  Команды запуска ИРЗ в ОС
--
-- Name: icts_run_commands; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 29 (номер схемы: 29)
--

CREATE TABLE imc.icts_run_commands (
    id_cmd uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_ict uuid NOT NULL,

    cmd text NOT NULL,

    order_to_run integer NOT NULL,

    CONSTRAINT icts_run_commands_1 UNIQUE (id_ict, order_to_run)

);


ALTER TABLE imc.icts_run_commands OWNER TO postgres;

--
-- Name: icts_run_commands pk_icts_run_commands; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_run_commands
    ADD CONSTRAINT pk_icts_run_commands PRIMARY KEY (id_cmd);

--
-- Name: icts_run_commands_id_cmd_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_run_commands_id_cmd_key ON imc.icts_run_commands USING btree (id_cmd);


ALTER TABLE ONLY imc.icts_run_commands
    ADD CONSTRAINT fk_icts_run_commands_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_run_commands
    ADD CONSTRAINT fk_icts_run_commands_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_run_commands
    ADD CONSTRAINT fk_icts_run_commands_id_ict FOREIGN KEY (id_ict) REFERENCES imc.icts_registry(id_ict);


--
-- Name: TABLE icts_run_commands; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_run_commands IS 'Команды запуска ИРЗ в ОС. Номер схемы: 29';


--
-- Name: COLUMN icts_run_commands.id_cmd; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_run_commands.id_cmd IS 'Идентификатор команды запуска ИРЗ в ОС';

--
-- Name: COLUMN icts_run_commands.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_run_commands.id_owner IS 'Владелец команды запуска ИРЗ в ОС (он же создатель)';


--
-- Name: COLUMN icts_run_commands.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_run_commands.created IS 'Когда создана команда запуска ИРЗ в ОС. Значение по умолчанию - now() по триггеру INSERT.';


--
-- Name: COLUMN icts_run_commands.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_run_commands.changed IS 'Когда изменена команда запуска ИРЗ в ОС. Значение по умолчанию - now() по триггеру UPDATE.';


--
-- Name: COLUMN icts_run_commands.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_run_commands.changed_by IS 'Кем изменена команда запуска ИРЗ в ОС';


--
-- Name: COLUMN icts_run_commands.id_ict; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_run_commands.id_ict IS 'Идентификатор ИРЗ, которой принадлежит команда запуска ИРЗ';


--
-- Name: COLUMN icts_run_commands.cmd; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_run_commands.cmd IS 'Текст команды запуска ИРЗ в ОС';


--
-- Name: COLUMN icts_cnf_params.order_to_run; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_run_commands.order_to_run IS 'Порядковый номер (номер позиции) команды в последовательности команд ИРЗ в ОС';












-- Таблица : Папки обмена данными с ИРЗ 
--
-- Name: icts_data_exchange_folders; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 30 (номер схемы: 30)
--

CREATE TABLE imc.icts_data_exchange_folders (
    id_folder uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_ict uuid NOT NULL,

    folder_path text NOT NULL

);


ALTER TABLE imc.icts_data_exchange_folders OWNER TO postgres;

--
-- Name: icts_data_exchange_folders pk_icts_data_exchange_folders; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_data_exchange_folders
    ADD CONSTRAINT pk_icts_data_exchange_folders PRIMARY KEY (id_folder);

--
-- Name: icts_data_exchange_folders_id_folder_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_data_exchange_folders_id_folder_key ON imc.icts_data_exchange_folders USING btree (id_folder);


ALTER TABLE ONLY imc.icts_data_exchange_folders
    ADD CONSTRAINT fk_icts_data_exchange_folders_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_data_exchange_folders
    ADD CONSTRAINT fk_icts_data_exchange_folders_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_data_exchange_folders
    ADD CONSTRAINT fk_icts_data_exchange_folders_id_ict FOREIGN KEY (id_ict) REFERENCES imc.icts_registry(id_ict);

--
-- Name: TABLE icts_data_exchange_folders; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_data_exchange_folders IS 'Папки обмена данными с ИРЗ. Номер схемы: 30';


--
-- Name: COLUMN icts_data_exchange_folders.id_folder; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_data_exchange_folders.id_folder IS 'Идентификатор папки обмена данными с ИРЗ';


--
-- Name: COLUMN icts_data_exchange_folders.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_data_exchange_folders.id_owner IS 'Владелец папки обмена данными с ИРЗ (он же создатель)';

--
-- Name: COLUMN icts_data_exchange_folders.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_data_exchange_folders.created IS 'Когда создана папка обмена данными с ИРЗ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN icts_data_exchange_folders.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_data_exchange_folders.changed IS 'Когда изменена папка обмена данными с ИРЗ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN icts_data_exchange_folders.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_data_exchange_folders.changed_by IS 'Кем изменена папка обмена данными с ИРЗ';

--
-- Name: COLUMN icts_data_exchange_folders.id_ict; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_data_exchange_folders.id_ict IS 'Идентификатор ИРЗ, которая будет использовать папку для обмена данными';

--
-- Name: COLUMN icts_data_exchange_folders.folder_path; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_data_exchange_folders.folder_path IS 'Путь к папке обмена данными с ИРЗ. Путь абослютный.';








-- Таблица : Виды СФЭ ИРЗ
--
-- Name: icts_sfe_kinds; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 31 (номер схемы: 31)
--

CREATE TABLE imc.icts_sfe_kinds (
    id_ict_sfe_kind uuid UNIQUE NOT NULL,
    id_ict_sfe_kind_inner integer NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_ict uuid NOT NULL,

    name text NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT icts_sfe_kinds_1 UNIQUE (id_ict, name),
    CONSTRAINT icts_sfe_kinds_2 UNIQUE (id_ict, order_in_list),
    CONSTRAINT icts_sfe_kinds_3 UNIQUE (id_ict, id_ict_sfe_kind_inner)

);


ALTER TABLE imc.icts_sfe_kinds OWNER TO postgres;

--
-- Name: icts_sfe_kinds pk_icts_sfe_kinds; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_sfe_kinds
    ADD CONSTRAINT pk_icts_sfe_kinds PRIMARY KEY (id_ict_sfe_kind);

--
-- Name: icts_sfe_kinds_id_ict_sfe_kind_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_sfe_kinds_id_ict_sfe_kind_key ON imc.icts_sfe_kinds USING btree (id_ict_sfe_kind);


ALTER TABLE ONLY imc.icts_sfe_kinds
    ADD CONSTRAINT fk_icts_sfe_kinds_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_sfe_kinds
    ADD CONSTRAINT fk_icts_sfe_kinds_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_sfe_kinds
    ADD CONSTRAINT fk_icts_sfe_kindss_id_ict FOREIGN KEY (id_ict) REFERENCES imc.icts_registry(id_ict);


--
-- Name: TABLE icts_sfe_kinds; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_sfe_kinds IS 'Виды СФЭ ИРЗ. Номер схемы: 31';


--
-- Name: COLUMN icts_sfe_kinds.id_ict_sfe_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_kinds.id_ict_sfe_kind IS 'Идентификатр вида СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfe_kinds.id_ict_sfe_kind_inner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_kinds.id_ict_sfe_kind_inner IS 'Идентификатр вида СФЭ ИРЗ внутри ИРЗ';

--
-- Name: COLUMN icts_sfe_kinds.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_kinds.id_owner IS 'Владелец вида СФЭ ИРЗ (он же создатель)';

--
-- Name: COLUMN icts_sfe_kinds.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_kinds.created IS 'Когда создан вид СФЭ ИРЗ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN icts_sfe_kinds.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_kinds.changed IS 'Когда изменен вид СФЭ ИРЗ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN icts_sfe_kinds.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_kinds.changed_by IS 'Кем изменен вид СФЭ ИРЗ';


-- Name: COLUMN icts_sfe_kinds.id_ict; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_kinds.id_ict IS 'Идентификатор ИРЗ, которой принадлежит вид СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfe_kinds.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_kinds.name IS 'Название вида СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfe_kinds.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_kinds.order_in_list IS 'Порядковый номер (номер позиции) вида СФЭ ИРЗ в списке видов ИРЗ (надо для организации web-интерфейсов)';








-- Таблица : Шаблоны СФЭ ИРЗ (ШСФЭ ИРЗ)
--
-- Name: icts_sfe_templates; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 32 (номер схемы: 32)
--

CREATE TABLE imc.icts_sfe_templates (
    id_ict_sfet uuid UNIQUE NOT NULL,
    id_ict_sfet_inner integer NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_ict_sfe_kind uuid NOT NULL,

    name text NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT icts_sfe_templates_1 UNIQUE (id_ict_sfe_kind, id_ict_sfet_inner),
    CONSTRAINT icts_sfe_templates_2 UNIQUE (id_ict_sfe_kind, name),
    CONSTRAINT icts_sfe_templates_3 UNIQUE (id_ict_sfe_kind, order_in_list)

);


ALTER TABLE imc.icts_sfe_templates OWNER TO postgres;

--
-- Name: icts_sfe_templates pk_icts_sfe_templates; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_sfe_templates
    ADD CONSTRAINT pk_icts_sfe_templates PRIMARY KEY (id_ict_sfet);

--
-- Name: icts_sfe_templates_id_ict_sfet_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_sfe_templates_id_ict_sfet_key ON imc.icts_sfe_templates USING btree (id_ict_sfet);


ALTER TABLE ONLY imc.icts_sfe_templates
    ADD CONSTRAINT fk_icts_sfe_templates_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_sfe_templates
    ADD CONSTRAINT fk_icts_sfe_templates_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_sfe_templates
    ADD CONSTRAINT fk_icts_sfe_templates_id_ict_sfe_kind FOREIGN KEY (id_ict_sfe_kind) REFERENCES imc.sfe_kinds(id_sfe_kind);

--
-- Name: TABLE icts_sfe_templates; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_sfe_templates IS 'Шаблоны СФЭ ИРЗ (ШСФЭ ИРЗ). Номер схемы: 32';


--
-- Name: COLUMN icts_sfe_templates.id_ict_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_templates.id_ict_sfet IS 'Идентификатор шаблона СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfe_templates.id_ict_sfet_inner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_templates.id_ict_sfet_inner IS 'Идентификатор шаблона СФЭ ИРЗ внутри ИРЗ';

--
-- Name: COLUMN icts_sfe_templates.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_templates.id_owner IS 'Владелец шаблона СФЭ ИРЗ (он же создатель)';

--
-- Name: COLUMN icts_sfe_templates.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_templates.created IS 'Когда создан шаблон СФЭ ИРЗ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN icts_sfe_templates.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_templates.changed IS 'Когда изменен шаблон СФЭ ИРЗ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN icts_sfe_templates.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_templates.changed_by IS 'Кем изменен шаблон СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfe_templates.id_ict_sfe_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_templates.id_ict_sfe_kind IS 'Идентификатор вида СФЭ ИРЗ, которому принадлежит шаблон СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfe_templates.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_templates.name IS 'Название шаблона СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfe_templates.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfe_templates.order_in_list IS 'Порядковый номер (номер позиции) шаблона СФЭ ИРЗ в списке шаблонов СФЭ ИРЗ одного вида СФЭ ИРЗ (надо для организации web-интерфейсов)';










-- Таблица : Связи шаблонов СФЭ ИРЗ
--
-- Name: icts_sfet_linkings; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 33 (номер схемы: 33)
--

CREATE TABLE imc.icts_sfet_linkings (
    id_ict_sfet_linking uuid UNIQUE NOT NULL,
    id_ict_sfet_linking_inner integer NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_ict_sfet uuid NOT NULL,
    id_lmd uuid NOT NULL,
    id_lmd_record uuid NOT NULL,

    id_ls_kind integer NOT NULL,

    id_ls_ict_sfe_kind uuid  DEFAULT NULL,
    id_ls_ict_sfet uuid DEFAULT NULL,

    id_ls_aec uuid DEFAULT NULL,
    id_ls_aec_record uuid DEFAULT NULL,

    CONSTRAINT icts_sfet_linkings_1 UNIQUE (id_ict_sfet, id_ict_sfet_linking_inner)


);


ALTER TABLE imc.icts_sfet_linkings OWNER TO postgres;

--
-- Name: icts_sfet_linkings pk_icts_sfet_linkings; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT pk_icts_sfet_linkings PRIMARY KEY (id_ict_sfet_linking);

--
-- Name: icts_sfet_linkings_id_ict_sfet_linking_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_sfet_linkings_id_ict_sfet_linking_key ON imc.icts_sfet_linkings USING btree (id_ict_sfet_linking);


ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT fk_icts_sfet_linkings_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT fk_icts_sfet_linkings_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT fk_icts_sfet_linkings_id_ict_sfet FOREIGN KEY (id_ict_sfet) REFERENCES imc.icts_sfe_templates(id_ict_sfet);


ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT fk_icts_sfet_linkings_id_lmd FOREIGN KEY (id_lmd) REFERENCES imc.dc_registry(id_dc);


ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT fk_icts_sfet_linkings_id_lmd_record FOREIGN KEY (id_lmd_record) REFERENCES imc.dc_records(id_record);


ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT fk_icts_sfet_linkings_id_ls_kind FOREIGN KEY (id_ls_kind) REFERENCES imc.sfet_ls_kinds(id_ls_kind);


ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT fk_icts_sfet_linkings_id_ls_ict_sfe_kind FOREIGN KEY (id_ls_ict_sfe_kind) REFERENCES imc.icts_sfe_kinds(id_ict_sfe_kind);


ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT fk_icts_sfet_linkings_id_ls_ict_sfet FOREIGN KEY (id_ls_ict_sfet) REFERENCES imc.icts_sfe_templates(id_ict_sfet);


ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT fk_icts_sfet_linkings_id_ls_aec FOREIGN KEY (id_ls_aec) REFERENCES imc.dc_registry(id_dc);


ALTER TABLE ONLY imc.icts_sfet_linkings
    ADD CONSTRAINT fk_icts_sfet_linkings_id_ls_aec_record FOREIGN KEY (id_ls_aec_record) REFERENCES imc.dc_records(id_record);


--
-- Name: TABLE icts_sfet_linkings; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_sfet_linkings IS 'Связи шаблонов СФЭ ИРЗ. Номер схемы: 33';


--
-- Name: COLUMN icts_sfet_linkings.id_ict_sfet_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_ict_sfet_linking IS 'Идентификатор связи шаблонов СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfet_linkings.id_ict_sfet_linking_inner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_ict_sfet_linking_inner IS 'Идентификатор связи шаблонов СФЭ ИРЗ внутри ИРЗ';


--
-- Name: COLUMN icts_sfet_linkings.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_owner IS 'Владелец связи шаблонов СФЭ ИРЗ (он же создатель)';

--
-- Name: COLUMN icts_sfet_linkings.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.created IS 'Когда создана связь шаблонов СФЭ ИРЗ . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN icts_sfet_linkings.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.changed IS 'Когда изменена связь шаблонов СФЭ ИРЗ . Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN icts_sfet_linkings.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.changed_by IS 'Кем изменена связь шаблонов СФЭ ИРЗ';


--
-- Name: COLUMN icts_sfet_linkings.id_ict_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_ict_sfet IS 'Идентификатор шаблона СФЭ ИРЗ, которому принадлежит связь';

--
-- Name: COLUMN icts_sfet_linkings.id_lmd; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_lmd IS 'Идентификатор словаря семантик связи шаблона СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfet_linkings.id_lmd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_lmd_record IS 'Идентификатор семантики связи из словаря семантик связи шаблонов СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfet_linkings.id_ls_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_ls_kind IS 'Идентификатор вида субъекта связи';

--
-- Name: COLUMN icts_sfet_linkings.id_ls_ict_sfe_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_ls_ict_sfe_kind IS 'Идентификатор вида СФЭ ИРЗ-субъекта связи';

--
-- Name: COLUMN icts_sfet_linkings.id_ls_ict_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_ls_ict_sfet IS 'Идентификатор шаблона СФЭ ИРЗ-субъекта связи';

--
-- Name: COLUMN icts_sfet_linkings.id_ls_aec; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_ls_aec IS 'Идентификатор каталога иных сущностей-субъектов связи шаблонов СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfet_linkings.id_ls_aec_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_linkings.id_ls_aec_record IS 'Идентификатор иной сущности (из каталога иных сущностей-субъектов связи шаблонов СФЭ ИРЗ)-субъекта связи';






-- Таблица : Свойства шаблонов СФЭ ИРЗ
--
-- Name: icts_sfet_properties; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 34 (номер схемы: 34)
--

CREATE TABLE imc.icts_sfet_properties (
    id_ict_sfet_property uuid UNIQUE NOT NULL,
    id_ict_sfet_property_inner integer NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_ict_sfet uuid NOT NULL,

    name_rus text NOT NULL,
    name_eng text NOT NULL,

    is_not_empty boolean NOT NULL,
    id_val_type integer NOT NULL,

    id_pvd uuid DEFAULT NULL,
    dv text DEFAULT NULL,
    dv_by_id_pvd_record uuid DEFAULT NULL,

    CONSTRAINT icts_sfet_properties_1 UNIQUE (id_ict_sfet, id_ict_sfet_property_inner),
    CONSTRAINT icts_sfet_properties_2 UNIQUE (id_ict_sfet, name_rus),
    CONSTRAINT icts_sfet_properties_3 UNIQUE (id_ict_sfet, name_eng)

);


ALTER TABLE imc.icts_sfet_properties OWNER TO postgres;

--
-- Name: icts_sfet_properties pk_icts_sfet_properties; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_sfet_properties
    ADD CONSTRAINT pk_icts_sfet_properties PRIMARY KEY (id_ict_sfet_property);

--
-- Name: icts_sfet_properties_id_ict_sfet_property_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_sfet_properties_id_ict_sfet_property_key ON imc.icts_sfet_properties USING btree (id_ict_sfet_property);


ALTER TABLE ONLY imc.icts_sfet_properties
    ADD CONSTRAINT fk_icts_sfet_properties_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_sfet_properties
    ADD CONSTRAINT fk_icts_sfet_properties_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_sfet_properties
    ADD CONSTRAINT fk_icts_sfet_properties_id_ict_sfet FOREIGN KEY (id_ict_sfet) REFERENCES imc.icts_sfe_templates(id_ict_sfet);


ALTER TABLE ONLY imc.icts_sfet_properties
    ADD CONSTRAINT fk_icts_sfet_properties_id_val_type FOREIGN KEY (id_val_type) REFERENCES imc.sfet_prop_val_types(id_val_type);



ALTER TABLE ONLY imc.icts_sfet_properties
    ADD CONSTRAINT fk_icts_sfet_properties_id_pvd FOREIGN KEY (id_pvd) REFERENCES imc.dc_registry(id_dc);


ALTER TABLE ONLY imc.icts_sfet_properties
    ADD CONSTRAINT fk_icts_sfet_properties_dv_by_id_pvd_record FOREIGN KEY (dv_by_id_pvd_record) REFERENCES imc.dc_records(id_record);



--
-- Name: TABLE icts_sfet_properties; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_sfet_properties IS 'Свойства шаблонов СФЭ ИРЗ. Номер схемы: 34';


--
-- Name: COLUMN icts_sfet_properties.id_ict_sfet_property; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.id_ict_sfet_property IS 'Идентификатор свойства шаблонов СФЭ ИРЗ';


--
-- Name: COLUMN icts_sfet_properties.id_ict_sfet_property_inner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.id_ict_sfet_property_inner IS 'Идентификатор свойства шаблонов СФЭ ИРЗ внутри ИРЗ';


--
-- Name: COLUMN icts_sfet_properties.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.id_owner IS 'Владелец свойства шаблонов СФЭ ИРЗ (он же создатель)';

--
-- Name: COLUMN v.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.created IS 'Когда создано свойство шаблонов СФЭ ИРЗ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN icts_sfet_properties.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.changed IS 'Когда изменено свойство шаблонов СФЭ ИРЗ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN icts_sfet_properties.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.changed_by IS 'Кем изменено свойство шаблонов СФЭ ИРЗ';

--
-- Name: COLUMN icts_sfet_properties.id_ict_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.id_ict_sfet IS 'Идентификатор шаблона СФЭ ИРЗ, которому принадлежит свойство';

--
-- Name: COLUMN icts_sfet_properties.name_rus; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.name_rus IS 'Русское название свойства';

--
-- Name: COLUMN icts_sfet_properties.name_eng; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.name_eng IS 'Английское название свойства';

--
-- Name: COLUMN icts_sfet_properties.is_not_empty; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.is_not_empty IS 'Должно ли быть задано значение свойства';

--
-- Name: COLUMN icts_sfet_properties.id_val_type; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.id_val_type IS 'Тип значения свойства';

--
-- Name: COLUMN icts_sfet_properties.id_pvd; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.id_pvd IS 'Идентификатор словаря возможных значений свойства (при id_val_type == 4)';

--
-- Name: COLUMN icts_sfet_properties.dv; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.dv IS 'Значение свойства по умолчанию';

--
-- Name: COLUMN icts_sfet_properties.dv_by_id_pvd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_sfet_properties.dv_by_id_pvd_record IS 'Значение свойства по умолчанию, заданное посредством идентификатора записи словаря возможных значений (для случая id_val_type == 4)';










-- Таблица : Целевые показатели ИРЗ
--
-- Name: icts_target_indicators; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 35 (номер схемы: 35)
--

CREATE TABLE imc.icts_target_indicators (
    id_ict_ti uuid UNIQUE NOT NULL,
    id_ict_ti_inner integer NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_ict uuid NOT NULL,

    name text NOT NULL,
    note text NOT NULL,

    is_calculated_by_default boolean NOT NULL,
    is_ict_sfet_property boolean NOT NULL,

    id_ict_sfet_property uuid DEFAULT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT icts_target_indicators_1 UNIQUE (id_ict, id_ict_ti_inner),
    CONSTRAINT icts_target_indicators_2 UNIQUE (id_ict, name),
    CONSTRAINT icts_target_indicators_3 UNIQUE (id_ict, order_in_list)

);


ALTER TABLE imc.icts_target_indicators OWNER TO postgres;

--
-- Name: icts_target_indicators pk_icts_target_indicators; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_target_indicators
    ADD CONSTRAINT pk_icts_target_indicators PRIMARY KEY (id_ict_ti);

--
-- Name: icts_target_indicators_id_ict_ti_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_target_indicators_id_ict_ti_key ON imc.icts_target_indicators USING btree (id_ict_ti);


ALTER TABLE ONLY imc.icts_target_indicators
    ADD CONSTRAINT fk_icts_target_indicators_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_target_indicators
    ADD CONSTRAINT fk_icts_target_indicators_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.icts_target_indicators
    ADD CONSTRAINT fk_icts_target_indicators_id_ict FOREIGN KEY (id_ict) REFERENCES imc.icts_registry(id_ict);


ALTER TABLE ONLY imc.icts_target_indicators
    ADD CONSTRAINT fk_icts_target_indicators_id_ict_sfet_property FOREIGN KEY (id_ict_sfet_property) REFERENCES imc.icts_sfet_properties(id_ict_sfet_property);


--
-- Name: TABLE icts_target_indicators; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_target_indicators IS 'Целевые показатели ИРЗ. Номер схемы: 35';


--
-- Name: COLUMN icts_target_indicators.id_ict_ti; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.id_ict_ti IS 'Идентификатор показателя ИРЗ';

--
-- Name: COLUMN icts_target_indicators.id_ict_ti_inner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.id_ict_ti_inner IS 'Идентификатор показателя ИРЗ внутри ИРЗ';


--
-- Name: COLUMN icts_target_indicators.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.id_owner IS 'Владелец показателя ИРЗ (он же создатель)';

--
-- Name: COLUMN icts_target_indicators.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.created IS 'Когда создан показатель ИРЗ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN icts_target_indicators.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.changed IS 'Когда изменен показатель ИРЗ. Значение по умолчанию - now() по триггеру UPDATE.';
--
-- Name: COLUMN icts_target_indicators.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.changed_by IS 'Кем изменен показатель ИРЗ';

--
-- Name: COLUMN icts_target_indicators.id_ict; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.id_ict IS 'Идентификатор ИРЗ, которой принадлежит показатель';

--
-- Name: COLUMN icts_target_indicators.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.name IS 'Название показателя';

--
-- Name: COLUMN icts_target_indicators.note; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.note IS 'Подсказка/заметка о показателе';

--
-- Name: COLUMN icts_target_indicators.is_calculated_by_default; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.is_calculated_by_default IS 'Вычисляется ли показатель по умолчанию';

--
-- Name: COLUMN icts_target_indicators.is_ict_sfet_property; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.is_ict_sfet_property IS 'Является ли показатель свойством шаблона СФЭ ИРЗ';

--
-- Name: COLUMN icts_target_indicators.id_ict_sfet_property; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.id_ict_sfet_property IS 'Идентификатор свойства шаблона СФЭ ИРЗ, являющегося показателем (для случая is_ict_sfet_property == True)';

--
-- Name: COLUMN icts_target_indicators.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_target_indicators.order_in_list IS 'Порядковый номер (номер позиции) показателя в списке показателей внутри одной ИРЗ (надо для организации web-интерфейсов)';











-- Таблица: Виды правил расчета ИРЗ 
--
-- Name: icts_calculation_rules_kinds; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 36 (номер схемы: 36)
--

CREATE TABLE imc.icts_calculation_rules_kinds (
    id_ict_calc_rule_kind integer UNIQUE NOT NULL,

    name text UNIQUE NOT NULL

);


ALTER TABLE imc.icts_calculation_rules_kinds OWNER TO postgres;

--
-- Name: icts_calculation_rules_kinds pk_icts_calculation_rules_kinds; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_calculation_rules_kinds
    ADD CONSTRAINT pk_icts_calculation_rules_kinds PRIMARY KEY (id_ict_calc_rule_kind);

--
-- Name: icts_calculation_rules_kinds_id_ict_calc_rule_kind_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_calculation_rules_kinds_id_ict_calc_rule_kind_key ON imc.icts_calculation_rules_kinds USING btree (id_ict_calc_rule_kind);



--
-- Name: TABLE icts_calculation_rules_kinds; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_calculation_rules_kinds IS 'Виды правил расчета ИРЗ. Номер схемы: 36';


--
-- Name: COLUMN icts_calculation_rules_kinds.id_ict_calc_rule_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_calculation_rules_kinds.id_ict_calc_rule_kind IS 'Идентификатор вида правила расчета ИРЗ';


--
-- Name: COLUMN icts_calculation_rules_kinds.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_calculation_rules_kinds.name IS 'Название вида правила расчета ИРЗ';




INSERT INTO imc.icts_calculation_rules_kinds (id_ict_calc_rule_kind, name) 
VALUES (1, 'Отождествить');

INSERT INTO imc.icts_calculation_rules_kinds (id_ict_calc_rule_kind, name) 
VALUES (2, 'Исключить');

INSERT INTO imc.icts_calculation_rules_kinds (id_ict_calc_rule_kind, name) 
VALUES (3, 'Добавить');

INSERT INTO imc.icts_calculation_rules_kinds (id_ict_calc_rule_kind, name) 
VALUES (4, 'Задать значение');








-- Таблица : Допустимые комбинации операндов правил расчета ИРЗ
--
-- Name: icts_calculation_rules_allowed_operands; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 37 (номер схемы: 37)
--

CREATE TABLE imc.icts_calculation_rules_allowed_operands (
    id_record uuid UNIQUE NOT NULL,

    id_ict_calc_rule_kind integer NOT NULL,
    id_operands_combination integer NOT NULL,

    operands_description text NOT NULL,
    operands_notation text NOT NULL,

    CONSTRAINT icts_calculation_rules_allowed_operands_1 UNIQUE (id_ict_calc_rule_kind, id_operands_combination)


);


ALTER TABLE imc.icts_calculation_rules_allowed_operands OWNER TO postgres;

--
-- Name: icts_calculation_rules_allowed_operands pk_icts_calculation_rules_allowed_operands; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.icts_calculation_rules_allowed_operands
    ADD CONSTRAINT pk_icts_calculation_rules_allowed_operands PRIMARY KEY (id_record);


ALTER TABLE ONLY imc.icts_calculation_rules_allowed_operands
    ADD CONSTRAINT fk_icts_calculation_rules_allowed_operands_id_ict_calc_rule_kind FOREIGN KEY (id_ict_calc_rule_kind) REFERENCES imc.icts_calculation_rules_kinds(id_ict_calc_rule_kind);



--
-- Name: icts_calculation_rules_allowed_operands_id_record_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_icts_calculation_rules_allowed_operands_id_record_key ON imc.icts_calculation_rules_allowed_operands USING btree (id_record);


--
-- Name: TABLE icts_calculation_rules_allowed_operands; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.icts_calculation_rules_allowed_operands IS 'Допустимые комбинации операндов правил расчета ИРЗ. Номер схемы: 37';

--
-- Name: COLUMN icts_calculation_rules_allowed_operands.id_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_calculation_rules_allowed_operands.id_record IS 'Идентификатор записи таблицы';

--
-- Name: COLUMN icts_calculation_rules_allowed_operands.id_ict_calc_rule_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_calculation_rules_allowed_operands.id_ict_calc_rule_kind IS 'Идентификатор вида правила расчета ИРЗ, которому принадлежит допустимая комбинация операндов';

--
-- Name: COLUMN icts_calculation_rules_allowed_operands.id_operands_combination; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_calculation_rules_allowed_operands.id_operands_combination IS 'Идентификатор допустимой комбинации операндов вида правила расчета ИРЗ. Уникален только внутри одного вида правила расчета ИРЗ';

--
-- Name: COLUMN icts_calculation_rules_allowed_operands.operands_description; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_calculation_rules_allowed_operands.operands_description IS 'Словесное описание допустимой комбинации операндов вида правила расчета ИРЗ';

--
-- Name: COLUMN icts_calculation_rules_allowed_operands.operands_notation; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.icts_calculation_rules_allowed_operands.operands_notation IS 'Нотация допустимой комбинации операндов вида правила расчета ИРЗ';



INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('fc1578aa-349f-4ca9-bfe9-f5849528826b', 1, 1, 'Словарь Модели со Словарем ИРЗ', 'СМ=СЗ');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('65fa5322-d53a-4d8b-a99a-ea7ddd7b2661', 1, 2, 'Каталог Модели с Каталогом ИРЗ', 'КМ=КЗ');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('446460e9-d7cb-44f8-aeea-66e6e9d8f766', 1, 3, 'Запись Словаря Модели с Записью Словаря ИРЗ', 'СМ.Зап=СЗ.Зап');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('f6aaa7b6-1c6d-4460-a31a-b9682bca3235', 1, 4, 'Запись Каталога Модели с Записью Каталога ИРЗ', 'КМ.Зап=КЗ.Зап');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('f8b49749-9280-4063-8562-6a9d90f049f4', 1, 5, 'Вид СФЭ Модели с Видом СФЭ ИРЗ', 'ВЭМ=ВЭЗ');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('df709daa-765b-445e-9ffd-7702d9818c84', 1, 6, 'Шаблон СФЭ Модели с Видом СФЭ ИРЗ', 'ШЭМ=ВЭЗ');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('87259615-b54c-49ed-b3c0-094a135e9a6a', 1, 7, 'Шаблон СФЭ Модели с Шаблоном СФЭ ИРЗ', 'ШЕМ=ЩЭЗ');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('6ff951e8-1ece-48f4-9b47-3b1200f6451e', 1, 8, 'Свойство Шаблона СФЭ Модели со Свойством Шаблона СФЭ ИРЗ', 'ШЭМ.Св=ШЭЗ.Св');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('de5e13f5-f151-4c28-975e-289ada191229', 1, 9, 'Связь Шаблона СФЭ Модели со Связью Шаблона СФЭ ИРЗ', 'ШЭМ.СвЗ=ШЭЗ.Свз');


INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('3b60a1e2-4e0f-4289-a291-094c953853cc', 2, 1, 'Вид СФЭ Модели', '-ВЭМ');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('414bd710-ab23-4a7d-a8d8-11aebe1ece5a', 2, 2, 'Шаблон СФЭ Модели', '-ШЕМ');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('f4ddc90e-d18f-4b27-bdb4-1dc053138e4f', 2, 3, 'СФЭ Модели', '-ЭМ');


INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('6c5ef20e-9acd-47d3-8da0-ba2332b37305', 3, 1, 'СФЭ Модели', '+ЭМ');


INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('a0e34bf1-01b5-4fd0-895b-6a493574a55c', 4, 1, 'Свойству СФЭ Модели', 'ШЭМ.Св=');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('5e254a96-8a52-4421-8c62-bf489e39fc45', 4, 2, 'Связи СФЭ Модели', 'ШЭМ.Свз=');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('53b5fa1a-8ce1-437a-a7f0-c12141635c7b', 4, 3, 'Свойству СФЭ Модели', 'ЭМ.Св=');

INSERT INTO imc.icts_calculation_rules_allowed_operands (id_record, id_ict_calc_rule_kind, id_operands_combination, operands_description, operands_notation) 
VALUES ('a3a99b66-c127-467a-b358-cca8a20fcaf6', 4, 4, 'Связи СФЭ Модели', 'ЭМ.Свз=');







-- Таблица : Группы моделей
--
-- Name: models_groups; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 38 (номер схемы: 38)
--

CREATE TABLE imc.models_groups (
    id_group uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_scheme uuid NOT NULL,
    id_parent_group uuid NOT NULL,

    is_root_group boolean NOT NULL DEFAULT TRUE,
    name text NOT NULL DEFAULT '(не задано)',
    order_in_list integer NOT NULL,

    CONSTRAINT models_groups_1 UNIQUE (id_parent_group, name),
    CONSTRAINT models_groups_2 UNIQUE (id_parent_group, order_in_list)

    -- Switch from this to partial inique index
    -- ,
    -- CONSTRAINT models_groups_3 UNIQUE (id_scheme, is_root_group)


);


ALTER TABLE imc.models_groups OWNER TO postgres;


CREATE UNIQUE INDEX models_groups_uni_idx1 ON imc.models_groups (id_scheme) WHERE (is_root_group = TRUE);

--
-- Name: models_groups pk_models_groups; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_groups
    ADD CONSTRAINT pk_models_groups PRIMARY KEY (id_group);

--
-- Name: models_groups_id_group_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_groups_id_group_key ON imc.models_groups USING btree (id_group);


ALTER TABLE ONLY imc.models_groups
    ADD CONSTRAINT fk_models_groups_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_groups
    ADD CONSTRAINT fk_models_groups_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_groups
    ADD CONSTRAINT fk_models_groups_id_scheme FOREIGN KEY (id_scheme) REFERENCES imc.schemes(id_scheme);


ALTER TABLE ONLY imc.models_groups
    ADD CONSTRAINT fk_models_groups_id_parent_group FOREIGN KEY (id_parent_group) REFERENCES imc.models_groups(id_group);

--
-- Name: TABLE models_groups; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_groups IS 'Группы моделей. Номер схемы: 38';


--
-- Name: COLUMN models_groups.id_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_groups.id_group IS 'Идентификатор группы моделей';


--
-- Name: COLUMN models_groups.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_groups.id_owner IS 'Владелец группы моделей (он же создатель)';

--
-- Name: COLUMN models_groups.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_groups.created IS 'Когда создана группа моделей. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_groups.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_groups.changed IS 'Когда изменена группа моделей. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_groups.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_groups.changed_by IS 'Кем изменена группа моделей';

--
-- Name: COLUMN models_groups.id_scheme; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_groups.id_scheme IS 'Идентификатор схемы, которой принадлежит группа';

--
-- Name: COLUMN models_groups.id_parent_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_groups.id_parent_group IS 'Идентификатор группы-родителя для группы';

--
-- Name: COLUMN models_groups.is_root_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_groups.is_root_group IS 'Является ли группа корнем дерева групп схемы';

--
-- Name: COLUMN models_groups.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_groups.name IS 'Название группы';

--
-- Name: COLUMN models_groups.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_groups.order_in_list IS 'Порядковый номер (номер позиции) группы в списке групп, имеющих одну родительскую группу (надо для организации web-интерфейсов)';















-- Таблица : Модели
--
-- Name: models; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 39 (номер схемы: 39)
--

CREATE TABLE imc.models (
    id_model uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_scheme uuid NOT NULL,

    name text NOT NULL DEFAULT '(не задано)',
    description text NOT NULL DEFAULT '(отсутствует)',

    now_calc_by_id_mod_calc uuid DEFAULT NULL,

    CONSTRAINT models_1 UNIQUE (id_scheme, name)

);


ALTER TABLE imc.models OWNER TO postgres;

--
-- Name: models pk_models; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models
    ADD CONSTRAINT pk_models PRIMARY KEY (id_model);

--
-- Name: models_id_model_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_id_model_key ON imc.models USING btree (id_model);


ALTER TABLE ONLY imc.models
    ADD CONSTRAINT fk_models_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models
    ADD CONSTRAINT fk_models_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models
    ADD CONSTRAINT fk_models_id_scheme FOREIGN KEY (id_scheme) REFERENCES imc.schemes(id_scheme);



--
-- Name: TABLE models; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models IS 'Модели. Номер схемы: 39';


--
-- Name: COLUMN models.id_model; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models.id_model IS 'Идентификатор модели';


--
-- Name: COLUMN models.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models.id_owner IS 'Владелец модели (он же создатель)';

--
-- Name: COLUMN models.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models.created IS 'Когда создана модель. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models.changed IS 'Когда изменена модель. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models.changed_by IS 'Кем изменена модель';


--
-- Name: COLUMN models.id_scheme; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models.id_scheme IS 'Идентификатор схемы, которой принадлежит модель';


--
-- Name: COLUMN models.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models.name IS 'Название модели';


--
-- Name: COLUMN models.description; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models.description IS 'Описание модели';


--
-- Name: COLUMN models.now_calc_by_id_mod_calc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models.now_calc_by_id_mod_calc IS 'Поле-семафор. Если значение поля не равно NULL, то модель в текущий момент обсчитывается "Расчетом Модели" (см. таблицу "models_calculations"), имеющим ID, равный значению поля. Перед каждым новым обсчетом Модели поле становится не равным NULL. По окончанию обсчета Модели поле становится равным NULL.';







-- Таблица : Вхождения моделей в группы моделей 
--
-- Name: models_in_their_groups; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 40 (номер схемы: 40)
--

CREATE TABLE imc.models_in_their_groups (
    id_entry uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_group uuid NOT NULL,
    id_model uuid NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT models_in_their_groups_1 UNIQUE (id_group, id_model),
    CONSTRAINT models_in_their_groups_2 UNIQUE (id_group, order_in_list)

);


ALTER TABLE imc.models_in_their_groups OWNER TO postgres;

--
-- Name: models_in_their_groups pk_models_in_their_groups; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_in_their_groups
    ADD CONSTRAINT pk_models_in_their_groups PRIMARY KEY (id_entry);

--
-- Name: models_in_their_groups_id_entry_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_in_their_groups_id_entry_key ON imc.models_in_their_groups USING btree (id_entry);


ALTER TABLE ONLY imc.models_in_their_groups
    ADD CONSTRAINT fk_models_in_their_groups_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_in_their_groups
    ADD CONSTRAINT fk_models_in_their_groups_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);



ALTER TABLE ONLY imc.models_in_their_groups
    ADD CONSTRAINT fk_models_in_their_groups_id_group FOREIGN KEY (id_group) REFERENCES imc.models_groups(id_group);


ALTER TABLE ONLY imc.models_in_their_groups
    ADD CONSTRAINT fk_models_in_their_groups_id_model FOREIGN KEY (id_model) REFERENCES imc.models(id_model);


--
-- Name: TABLE models_in_their_groups; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_in_their_groups IS 'Вхождения моделей в группы моделей. Номер схемы: 40';


--
-- Name: COLUMN models_in_their_groups.id_entry; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_in_their_groups.id_entry IS 'Идентификатор вхождения';


--
-- Name: COLUMN models_in_their_groups.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_in_their_groups.id_owner IS 'Владелец вхождения (он же создатель)';

--
-- Name: COLUMN models_in_their_groups.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_in_their_groups.created IS 'Когда создано вхождения . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_in_their_groups.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_in_their_groups.changed IS 'Когда изменено вхождения . Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_in_their_groups.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_in_their_groups.changed_by IS 'Кем изменено вхождения ';

--
-- Name: COLUMN models_in_their_groups.id_group; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_in_their_groups.id_group IS 'Идентификатор группы модели, которая входит в группу моделей';

--
-- Name: COLUMN c.id_model; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_in_their_groups.id_model IS 'Идентификатор модели, которая входит в группу моделей';

--
-- Name: COLUMN id_model.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_in_their_groups.order_in_list IS 'Порядковый номер (номер позиции) модели в списке моделей внутри одной группы моделей (надо для организации web-интерфейсов)';











-- Таблица : СФЭ моделей 
--
-- Name: models_sfe; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 41 (номер схемы: 41)
--

CREATE TABLE imc.models_sfe (
    id_sfe uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_model uuid NOT NULL,
    id_sfet uuid NOT NULL,

    vr_code text NOT NULL DEFAULT '(не задан)',

    CONSTRAINT models_sfe_1 UNIQUE (id_model, vr_code)

);


ALTER TABLE imc.models_sfe OWNER TO postgres;

--
-- Name: models_sfe pk_models_sfe; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_sfe
    ADD CONSTRAINT pk_models_sfe PRIMARY KEY (id_sfe);

--
-- Name: models_sfe_id_sfe_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_sfe_id_sfe_key ON imc.models_sfe USING btree (id_sfe);


ALTER TABLE ONLY imc.models_sfe
    ADD CONSTRAINT fk_models_sfe_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_sfe
    ADD CONSTRAINT fk_models_sfe_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_sfe
    ADD CONSTRAINT fk_models_sfe_id_model FOREIGN KEY (id_model) REFERENCES imc.models(id_model);


ALTER TABLE ONLY imc.models_sfe
    ADD CONSTRAINT fk_models_sfe_id_sfet FOREIGN KEY (id_sfet) REFERENCES imc.sfe_templates(id_sfet);


--
-- Name: TABLE models_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_sfe IS 'СФЭ моделей. Номер схемы: 41';


--
-- Name: COLUMN models_sfe.id_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe.id_sfe IS 'Идентификатор СФЭ';


--
-- Name: COLUMN models_sfe.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe.id_owner IS 'Владелец СФЭ (он же создатель)';

--
-- Name: COLUMN models_sfe.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe.created IS 'Когда создан СФЭ . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_sfe.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe.changed IS 'Когда изменен СФЭ . Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_sfe.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe.changed_by IS 'Кем изменен СФЭ';

--
-- Name: COLUMN models_sfe.id_model; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe.id_model IS 'Идентификатор модели, котрой принадлежит СФЭ';

--
-- Name: COLUMN models_sfe.id_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe.id_sfet IS 'Идентификатор шаблона СФЭ, на основе которого создан СФЭ';

--
-- Name: COLUMN models_sfe.vr_code; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe.vr_code IS 'Код визуального распознания СФЭ (уникален в пределах модели). Задается пользователем вручную';








-- Таблица : Связи СФЭ моделей
--
-- Name: models_sfe_linkings; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 42 (номер схемы: 42)
--

CREATE TABLE imc.models_sfe_linkings (
    id_sfe_linking uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfe uuid NOT NULL,
    id_sfet_linking uuid NOT NULL,
    id_lmd_record uuid NOT NULL,
    id_ls_sfe uuid DEFAULT NULL,
    id_ls_aec_record uuid DEFAULT NULL,

    CONSTRAINT models_sfe_linkings_1 UNIQUE (id_sfe, id_sfet_linking, id_lmd_record, id_ls_sfe),
    CONSTRAINT models_sfe_linkings_2 UNIQUE (id_sfe, id_sfet_linking, id_lmd_record, id_ls_aec_record)

);


ALTER TABLE imc.models_sfe_linkings OWNER TO postgres;

--
-- Name: models_sfe_linkings pk_models_sfe_linkings; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_sfe_linkings
    ADD CONSTRAINT pk_models_sfe_linkings PRIMARY KEY (id_sfe_linking);

--
-- Name: models_sfe_linkings_id_sfe_linking_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_sfe_linkings_id_sfe_linking_key ON imc.models_sfe_linkings USING btree (id_sfe_linking);


ALTER TABLE ONLY imc.models_sfe_linkings
    ADD CONSTRAINT fk_models_sfe_linkings_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_sfe_linkings
    ADD CONSTRAINT fk_models_sfe_linkings_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_sfe_linkings
    ADD CONSTRAINT fk_models_sfe_linkings_id_sfe FOREIGN KEY (id_sfe) REFERENCES imc.models_sfe(id_sfe);


ALTER TABLE ONLY imc.models_sfe_linkings
    ADD CONSTRAINT fk_models_sfe_linkings_id_sfet_linking FOREIGN KEY (id_sfet_linking) REFERENCES imc.sfet_linkings(id_sfet_linking);


ALTER TABLE ONLY imc.models_sfe_linkings
    ADD CONSTRAINT fk_models_sfe_linkings_id_lmd_record FOREIGN KEY (id_lmd_record) REFERENCES imc.dc_records(id_record);


ALTER TABLE ONLY imc.models_sfe_linkings
    ADD CONSTRAINT fk_models_sfe_linkings_id_ls_sfe FOREIGN KEY (id_ls_sfe) REFERENCES imc.models_sfe(id_sfe);


ALTER TABLE ONLY imc.models_sfe_linkings
    ADD CONSTRAINT fk_models_sfe_linkings_id_ls_aec_record FOREIGN KEY (id_ls_aec_record) REFERENCES imc.dc_records(id_record);



--
-- Name: TABLE models_sfe_linkings; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_sfe_linkings IS 'Связи СФЭ моделей. Номер схемы: 42';


--
-- Name: COLUMN models_sfe_linkings.id_sfe_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_linkings.id_sfe_linking IS 'Идентификатор связи СФЭ';


--
-- Name: COLUMN models_sfe_linkings.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_linkings.id_owner IS 'Владелец связи СФЭ (он же создатель)';

--
-- Name: COLUMN models_sfe_linkings.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_linkings.created IS 'Когда создана связь СФЭ . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_sfe_linkings.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_linkings.changed IS 'Когда изменена связь СФЭ . Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_sfe_linkings.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_linkings.changed_by IS 'Кем изменена связь СФЭ ';


--
-- Name: COLUMN models_sfe_linkings.id_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_linkings.id_sfe IS 'Идентификатор СФЭ, которому принадлежит связь';


--
-- Name: COLUMN models_sfe_linkings.id_sfet_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_linkings.id_sfet_linking IS 'Идентификатор шаблона СФЭ, по которому создана связь СФЭ';


--
-- Name: COLUMN models_sfe_linkings.id_lmd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_linkings.id_lmd_record IS 'Идентификатор записи семантики связи СФЭ';


--
-- Name: COLUMN models_sfe_linkings.id_ls_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_linkings.id_ls_sfe IS 'Идентификатор СФЭ-субъекта связи';


--
-- Name: COLUMN models_sfe_linkings.id_ls_aec_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_linkings.id_ls_aec_record IS 'Идентификатор записи каталога иных сущностей-субъекта связи';





-- Таблица : Свойства СФЭ моделей
--
-- Name: models_sfe_properties; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 43 (номер схемы: 43)
--

CREATE TABLE imc.models_sfe_properties (
    id_sfe_property uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfe uuid NOT NULL,
    id_sfet_property uuid NOT NULL,

    val text DEFAULT NULL,
    val_by_id_pvd_record uuid DEFAULT NULL,

    CONSTRAINT models_sfe_properties_1 UNIQUE (id_sfe, id_sfet_property)


);


ALTER TABLE imc.models_sfe_properties OWNER TO postgres;

--
-- Name: models_sfe_properties pk_models_sfe_properties; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_sfe_properties
    ADD CONSTRAINT pk_models_sfe_properties PRIMARY KEY (id_sfe_property);

--
-- Name: models_sfe_properties_id_sfe_property_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_sfe_properties_id_sfe_property_key ON imc.models_sfe_properties USING btree (id_sfe_property);


ALTER TABLE ONLY imc.models_sfe_properties
    ADD CONSTRAINT fk_models_sfe_properties_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_sfe_properties
    ADD CONSTRAINT fk_models_sfe_properties_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);



ALTER TABLE ONLY imc.models_sfe_properties
    ADD CONSTRAINT fk_models_sfe_properties_id_sfe FOREIGN KEY (id_sfe) REFERENCES imc.models_sfe(id_sfe);


ALTER TABLE ONLY imc.models_sfe_properties
    ADD CONSTRAINT fk_models_sfe_properties_id_sfet_property FOREIGN KEY (id_sfet_property) REFERENCES imc.sfet_properties(id_sfet_property);


ALTER TABLE ONLY imc.models_sfe_properties
    ADD CONSTRAINT fk_models_sfe_properties_val_by_id_pvd_record FOREIGN KEY (val_by_id_pvd_record) REFERENCES imc.dc_records(id_record);




--
-- Name: TABLE models_sfe_properties; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_sfe_properties IS 'Свойства СФЭ моделей. Номер схемы: 43';


--
-- Name: COLUMN models_sfe_properties.id_sfe_property; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_properties.id_sfe_property IS 'Идентификатор свойства СФЭ';


--
-- Name: COLUMN models_sfe_properties.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_properties.id_owner IS 'Владелец свойства СФЭ (он же создатель)';

--
-- Name: COLUMN models_sfe_properties.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_properties.created IS 'Когда создано свойство СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_sfe_properties.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_properties.changed IS 'Когда изменено свойство СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_sfe_properties.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_properties.changed_by IS 'Кем изменено свойство СФЭ';


--
-- Name: COLUMN models_sfe_properties.id_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_properties.id_sfe IS 'Идентификатор СФЭ, которому принадлежит свойство';


--
-- Name: COLUMN models_sfe_properties.id_sfet_property; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_properties.id_sfet_property IS 'Идентификатор свойства шаблона СФЭ, по которому создано свойство СФЭ';


--
-- Name: COLUMN models_sfe_properties.val; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_properties.val IS 'Значение свойства СФЭ';


--
-- Name: COLUMN models_sfe_properties.val_by_id_pvd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_sfe_properties.val_by_id_pvd_record IS 'Идентификатор записи словаря возможных значений, если значение свойства СФЭ является записью из этого словаря';








-- Таблица : Расчеты моделей
--
-- Name: models_calculations; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 44 (номер схемы: 44)
--

CREATE TABLE imc.models_calculations (
    id_mod_calc uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_model uuid NOT NULL,
    id_ict uuid NOT NULL,

    name text NOT NULL,

    calc_start_at timestamp without time zone DEFAULT NULL,
    calc_stop_at timestamp without time zone DEFAULT NULL,
    calc_by uuid DEFAULT NULL,
    calc_status text DEFAULT NULL,
    is_calc_success boolean DEFAULT NULL,
    calc_note text DEFAULT NULL,

    CONSTRAINT models_calculations_1 UNIQUE (id_model, id_ict, name)


);


ALTER TABLE imc.models_calculations OWNER TO postgres;

--
-- Name: models_calculations pk_models_calculations; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_calculations
    ADD CONSTRAINT pk_models_calculations PRIMARY KEY (id_mod_calc);

--
-- Name: models_calculations_id_mod_calc_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_calculations_id_mod_calc_key ON imc.models_calculations USING btree (id_mod_calc);


ALTER TABLE ONLY imc.models_calculations
    ADD CONSTRAINT fk_models_calculations_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations
    ADD CONSTRAINT fk_models_calculations_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations
    ADD CONSTRAINT fk_models_calculations_id_model FOREIGN KEY (id_model) REFERENCES imc.models(id_model);


ALTER TABLE ONLY imc.models_calculations
    ADD CONSTRAINT fk_models_calculations_id_ict FOREIGN KEY (id_ict) REFERENCES imc.icts_registry(id_ict);


ALTER TABLE ONLY imc.models_calculations
    ADD CONSTRAINT fk_models_calculations_calc_by FOREIGN KEY (calc_by) REFERENCES imc.users(id_user);


--
-- Name: TABLE models_calculations; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_calculations IS 'Расчеты моделей. Номер схемы: 44';


--
-- Name: COLUMN models_calculations.id_mod_calc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.id_mod_calc IS 'Идентификатор расчета модели';


--
-- Name: COLUMN models_calculations.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.id_owner IS 'Владелец расчета модели (он же создатель)';

--
-- Name: COLUMN models_calculations.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.created IS 'Когда создан расчет модели . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN v.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.changed IS 'Когда изменен расчет модели. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_calculations.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.changed_by IS 'Кем изменен расчет модели';


--
-- Name: COLUMN models_calculations.id_model; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.id_model IS 'Идентификатор модели, которая будет рссчитываться';

--
-- Name: COLUMN models_calculations.id_ict; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.id_ict IS 'Идентификатор ИРЗ, которая будет рссчитывать модель';


--
-- Name: COLUMN models_calculations.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.name IS 'Название расчета модели';


--
-- Name: COLUMN models_calculations.calc_start_at; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.calc_start_at IS 'Когда начат расчет модели';


--
-- Name: COLUMN models_calculations.calc_stop_at; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.calc_stop_at IS 'Когда закончен расчет модели';


--
-- Name: COLUMN models_calculations.calc_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.calc_by IS 'Кем выполнен расчет модели';


--
-- Name: COLUMN models_calculations.calc_status; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.calc_status IS 'Текущий статус выполнения расчета модели';


--
-- Name: COLUMN models_calculations.is_calc_success; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.is_calc_success IS 'Успешно ли выполенен расчет модели';


--
-- Name: COLUMN models_calculations.calc_note; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations.calc_note IS 'Заметка о результате расчета. Заполняется ползователем вручную, если ему это надо';







-- Таблица : Правила расчетов моделей
--
-- Name: models_calculations_rules; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 45 (номер схемы: 45)
--

CREATE TABLE imc.models_calculations_rules (
    id_rule uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_mod_calc uuid NOT NULL,
    id_allowed_operands_combination uuid NOT NULL,

    f1 text DEFAULT NULL,
    f2 text DEFAULT NULL,
    f3 text DEFAULT NULL,
    f4 text DEFAULT NULL,
    f5 text DEFAULT NULL,
    f6 text DEFAULT NULL,
    notation text NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT models_calculations_rules_1 UNIQUE (id_mod_calc, order_in_list)

);


ALTER TABLE imc.models_calculations_rules OWNER TO postgres;

--
-- Name: models_calculations_rules pk_models_calculations_rules; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_calculations_rules
    ADD CONSTRAINT pk_models_calculations_rules PRIMARY KEY (id_rule);

--
-- Name: models_calculations_rules_id_rule_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_calculations_rules_id_rule_key ON imc.models_calculations_rules USING btree (id_rule);


ALTER TABLE ONLY imc.models_calculations_rules
    ADD CONSTRAINT fk_models_calculations_rules_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_rules
    ADD CONSTRAINT fk_models_calculations_rules_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_rules
    ADD CONSTRAINT fk_models_calculations_rules_id_mod_calc FOREIGN KEY (id_mod_calc) REFERENCES imc.models_calculations(id_mod_calc);


ALTER TABLE ONLY imc.models_calculations_rules
    ADD CONSTRAINT fk_models_calculations_rules_id_allowed_operands_combination FOREIGN KEY (id_allowed_operands_combination) REFERENCES imc.icts_calculation_rules_allowed_operands (id_record);



--
-- Name: TABLE models_calculations_rules; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_calculations_rules IS 'Правила расчетов моделей. Номер схемы: 45';


--
-- Name: COLUMN models_calculations_rules.id_rule; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.id_rule IS 'Идентификатор правила';


--
-- Name: COLUMN models_calculations_rules.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.id_owner IS 'Владелец правила (он же создатель)';

--
-- Name: COLUMN models_calculations_rules.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.created IS 'Когда создано правила . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_calculations_rules.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.changed IS 'Когда изменено правила . Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_calculations_rules.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.changed_by IS 'Кем изменено правила ';


--
-- Name: COLUMN models_calculations_rules.id_mod_calc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.id_mod_calc IS 'Идентификатор расчета модели, которому принадлежит правило';

--
-- Name: COLUMN models_calculations_rules.id_allowed_operands_combination; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.id_allowed_operands_combination IS 'Идентификатор записи таблицы "icts_calculation_rules_allowed_operands", характеризующей комбинацию операндов для правила расчета модели ';

--
-- Name: COLUMN models_calculations_rules.f1; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.f1 IS 'Операнд 1 правила расчета модели';

--
-- Name: COLUMN models_calculations_rules.f2; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.f2 IS 'Операнд 2 правила расчета модели';

--
-- Name: COLUMN models_calculations_rules.f3; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.f3 IS 'Операнд 3 правила расчета модели';

--
-- Name: COLUMN models_calculations_rules.f4; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.f4 IS 'Операнд 4 правила расчета модели';

--
-- Name: COLUMN models_calculations_rules.f5; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.f5 IS 'Операнд 5 правила расчета модели';

--
-- Name: COLUMN models_calculations_rules.f6; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.f6 IS 'Операнд 6 правила расчета модели';

--
-- Name: COLUMN models_calculations_rules.notation; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.notation IS 'Нотация правила расчета модели';

--
-- Name: COLUMN models_calculations_rules.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_rules.order_in_list IS 'Порядковый номер (номер позиции) правила в списке правил внутри одного расчета модели (надо для организации web-интерфейсов)';





-- Таблица : Целевые показатели расчетов моделей
--
-- Name: models_calculations_target_indicators; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 46 (номер схемы: 46)
--

CREATE TABLE imc.models_calculations_target_indicators (
    id_mod_calc_ti uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_mod_calc uuid NOT NULL,
    id_ict_ti uuid NOT NULL,

    do_calc boolean NOT NULL,

    use_name text NOT NULL,
    calc_value text DEFAULT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT models_calculations_target_indicators_1 UNIQUE (id_mod_calc, use_name),
    CONSTRAINT models_calculations_target_indicators_2 UNIQUE (id_mod_calc, id_ict_ti),
    CONSTRAINT models_calculations_target_indicators_3 UNIQUE (id_mod_calc, order_in_list)


);


ALTER TABLE imc.models_calculations_target_indicators OWNER TO postgres;

--
-- Name: models_calculations_target_indicators pk_models_calculations_target_indicators; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_calculations_target_indicators
    ADD CONSTRAINT pk_models_calculations_target_indicators PRIMARY KEY (id_mod_calc_ti);

--
-- Name: models_calculations_target_indicators_id_mod_calc_ti_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_calculations_target_indicators_id_mod_calc_ti_key ON imc.models_calculations_target_indicators USING btree (id_mod_calc_ti);


ALTER TABLE ONLY imc.models_calculations_target_indicators
    ADD CONSTRAINT fk_models_calculations_target_indicators_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_target_indicators
    ADD CONSTRAINT fk_models_calculations_target_indicators_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_target_indicators
    ADD CONSTRAINT fk_models_calculations_target_indicators_id_mod_calc FOREIGN KEY (id_mod_calc) REFERENCES imc.models_calculations(id_mod_calc);


ALTER TABLE ONLY imc.models_calculations_target_indicators
    ADD CONSTRAINT fk_models_calculations_target_indicators_id_ict_ti FOREIGN KEY (id_ict_ti) REFERENCES imc.icts_target_indicators(id_ict_ti);


--
-- Name: TABLE models_calculations_target_indicators; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_calculations_target_indicators IS 'Целевые показатели расчетов моделей. Номер схемы: 46';


--
-- Name: COLUMN models_calculations_target_indicators.id_mod_calc_ti; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.id_mod_calc_ti IS 'Идентификатор показателя';


--
-- Name: COLUMN models_calculations_target_indicators.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.id_owner IS 'Владелец показателя (он же создатель)';

--
-- Name: COLUMN models_calculations_target_indicators.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.created IS 'Когда создан показатель . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_calculations_target_indicators.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.changed IS 'Когда изменен показатель. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_calculations_target_indicators.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.changed_by IS 'Кем изменен показатель';


--
-- Name: COLUMN models_calculations_target_indicators.id_mod_calc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.id_mod_calc IS 'Идентификатор расчета модели, которому принадлежит показатель';

--
-- Name: COLUMN models_calculations_target_indicators.id_ict_ti; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.id_ict_ti IS 'Идентификатор целевого показателя ИРЗ, на основе которого создан целевой показатель расчета модели';

--
-- Name: COLUMN models_calculations_target_indicators.do_calc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.do_calc IS 'Вычислять ли значение показателя при расчете модели';

--
-- Name: COLUMN models_calculations_target_indicators.use_name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.use_name IS 'Какое имя для показателя использовать в результатах расчета модели и в отчетах о выполнении модели';

--
-- Name: COLUMN models_calculations_target_indicators.calc_value; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.calc_value IS 'Вычисленное значение показателя, если он не задан как свойство шаблона СФЭ ИРЗ';

--
-- Name: COLUMN models_calculations_target_indicators.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_target_indicators.order_in_list IS 'Порядковый номер (номер позиции) правила в списке правил внутри одного расчета модели (надо для организации web-интерфейсов)';









-- Таблица : Конфигурационные параметры ИРЗ для расчетов моделей 
--
-- Name: models_calculations_cnf_params; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 47 (номер схемы: 47)
--

CREATE TABLE imc.models_calculations_cnf_params (
    id_mod_calc_param uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_mod_calc uuid NOT NULL,
    id_ict_param uuid NOT NULL,

    val text NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT models_calculations_cnf_params_1 UNIQUE (id_mod_calc, id_ict_param),
    CONSTRAINT models_calculations_cnf_params_2 UNIQUE (id_mod_calc, order_in_list)


);


ALTER TABLE imc.models_calculations_cnf_params OWNER TO postgres;

--
-- Name: models_calculations_cnf_params pk_models_calculations_cnf_params; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_calculations_cnf_params
    ADD CONSTRAINT pk_models_calculations_cnf_params PRIMARY KEY (id_mod_calc_param);

--
-- Name: models_calculations_cnf_params_id_mod_calc_param_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_calculations_cnf_params_id_mod_calc_param_key ON imc.models_calculations_cnf_params USING btree (id_mod_calc_param);


ALTER TABLE ONLY imc.models_calculations_cnf_params
    ADD CONSTRAINT fk_models_calculations_cnf_params_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_cnf_params
    ADD CONSTRAINT fk_models_calculations_cnf_params_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_cnf_params
    ADD CONSTRAINT fk_models_calculations_cnf_params_id_mod_calc FOREIGN KEY (id_mod_calc) REFERENCES imc.models_calculations(id_mod_calc);


ALTER TABLE ONLY imc.models_calculations_cnf_params
    ADD CONSTRAINT fk_models_calculations_cnf_params_id_ict_param FOREIGN KEY (id_ict_param) REFERENCES imc.icts_cnf_params(id_param);


--
-- Name: TABLE models_calculations_cnf_params; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_calculations_cnf_params IS 'Конфигурационные параметры ИРЗ для расчетов моделей. Номер схемы: 47';


--
-- Name: COLUMN models_calculations_cnf_params.id_mod_calc_param; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_cnf_params.id_mod_calc_param IS 'Идентификатор параметра';


--
-- Name: COLUMN models_calculations_cnf_params.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_cnf_params.id_owner IS 'Владелец параметра (он же создатель)';

--
-- Name: COLUMN models_calculations_cnf_params.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_cnf_params.created IS 'Когда создан параметр . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_calculations_cnf_params.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_cnf_params.changed IS 'Когда изменен параметр . Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_calculations_cnf_params.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_cnf_params.changed_by IS 'Кем изменен параметр';


--
-- Name: COLUMN models_calculations_cnf_params.id_mod_calc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_cnf_params.id_mod_calc IS 'Идентификатор расчета модели, которому принадлежит параметр';

--
-- Name: COLUMN models_calculations_cnf_params.id_ict_param; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_cnf_params.id_ict_param IS 'Идентификатор конфигурационного параметра ИРЗ, на основе которого создан параметр';

--
-- Name: COLUMN models_calculations_cnf_params.val; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_cnf_params.val IS 'Значение параметра';

--
-- Name: COLUMN models_calculations_cnf_params.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_cnf_params.order_in_list IS 'Порядковый номер (номер позиции) параметра в списке параметров внутри одного расчета модели (надо для организации web-интерфейсов)';









-- Таблица : Результирующие модели
--
-- Name: resulting_models; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 48 (номер схемы: 48)
--

CREATE TABLE imc.resulting_models (
    id_res_model uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_mod_calc uuid UNIQUE NOT NULL

);


ALTER TABLE imc.resulting_models OWNER TO postgres;

--
-- Name: resulting_models pk_v; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.resulting_models
    ADD CONSTRAINT pk_resulting_models PRIMARY KEY (id_res_model);

--
-- Name: resulting_models_id_res_model_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_resulting_models_id_res_model_key ON imc.resulting_models USING btree (id_res_model);


ALTER TABLE ONLY imc.resulting_models
    ADD CONSTRAINT fk_resulting_models_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.resulting_models
    ADD CONSTRAINT fk_resulting_models_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.resulting_models
    ADD CONSTRAINT fk_resulting_models_id_mod_calc FOREIGN KEY (id_mod_calc) REFERENCES imc.models_calculations(id_mod_calc);


--
-- Name: TABLE resulting_models; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.resulting_models IS 'Результирующие модели. Номер схемы: 48';


--
-- Name: COLUMN resulting_models.id_res_model; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models.id_res_model IS ' модели';


--
-- Name: COLUMN resulting_models.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models.id_owner IS 'Владелец модели (он же создатель)';

--
-- Name: COLUMN resulting_models.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models.created IS 'Когда создана модель . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN resulting_models.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models.changed IS 'Когда изменена модель . Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN resulting_models.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models.changed_by IS 'Кем изменена модель ';


--
-- Name: COLUMN resulting_models.id_mod_calc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models.id_mod_calc IS 'Идентификатор расчета модели, которому принадлежит модель';







-- Таблица : Отчеты о расчетах моделей
--
-- Name: models_calculations_reports; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 49 (номер схемы: 49)
--

CREATE TABLE imc.models_calculations_reports (
    id_mod_calc_report uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_mod_calc uuid UNIQUE NOT NULL,

    content bytea NOT NULL

);


ALTER TABLE imc.models_calculations_reports OWNER TO postgres;

--
-- Name: models_calculations_reports pk_models_calculations_reports; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_calculations_reports
    ADD CONSTRAINT pk_models_calculations_reports PRIMARY KEY (id_mod_calc_report);

--
-- Name: models_calculations_reports_id_mod_calc_report_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_calculations_reports_id_mod_calc_report_key ON imc.models_calculations_reports USING btree (id_mod_calc_report);


ALTER TABLE ONLY imc.models_calculations_reports
    ADD CONSTRAINT fk_models_calculations_reports_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_reports
    ADD CONSTRAINT fk_models_calculations_reports_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_reports
    ADD CONSTRAINT fk_models_calculations_reports_id_mod_calc FOREIGN KEY (id_mod_calc) REFERENCES imc.models_calculations(id_mod_calc);


--
-- Name: TABLE models_calculations_reports; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_calculations_reports IS 'Отчеты о расчетах моделей. Номер схемы: 49';


--
-- Name: COLUMN models_calculations_reports.id_mod_calc_report; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports.id_mod_calc_report IS 'Идентификатор отчета';


--
-- Name: COLUMN models_calculations_reports.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports.id_owner IS 'Владелец отчета (он же создатель)';

--
-- Name: COLUMN models_calculations_reports.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports.created IS 'Когда создан отчета. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_calculations_reports.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports.changed IS 'Когда изменен отчет. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_calculations_reports.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports.changed_by IS 'Кем изменен отчет';

--
-- Name: COLUMN models_calculations_reports.id_mod_calc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports.id_mod_calc IS 'Идентификатор расчета модели, которому принадлежит отчет';

--
-- Name: COLUMN models_calculations_reports.content; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports.content IS 'Содержимое отчета';





-- Таблица : Файлы с результатами расчетов моделей
--
-- Name: models_calculations_result_files; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 50 (номер схемы: 50)
--

CREATE TABLE imc.models_calculations_result_files (
    id_result_file uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_mod_calc uuid UNIQUE NOT NULL,
    file_path text NOT NULL,


    CONSTRAINT models_calculations_result_files_1 UNIQUE (id_mod_calc, file_path)

);


ALTER TABLE imc.models_calculations_result_files OWNER TO postgres;

--
-- Name: models_calculations_result_files pk_models_calculations_result_files; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_calculations_result_files
    ADD CONSTRAINT pk_models_calculations_result_files PRIMARY KEY (id_result_file);

--
-- Name: models_calculations_result_files_id_result_file_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_calculations_result_files_id_result_file_key ON imc.models_calculations_result_files USING btree (id_result_file);


ALTER TABLE ONLY imc.models_calculations_result_files
    ADD CONSTRAINT fk_models_calculations_result_files_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_result_files
    ADD CONSTRAINT fk_models_calculations_result_files_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_result_files
    ADD CONSTRAINT fk_models_calculations_result_files_id_mod_calc FOREIGN KEY (id_mod_calc) REFERENCES imc.models_calculations(id_mod_calc);



--
-- Name: TABLE models_calculations_result_files; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_calculations_result_files IS 'Файлы с результатами расчетов моделей. Номер схемы: 50';


--
-- Name: COLUMN models_calculations_result_files.id_result_file; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_result_files.id_result_file IS 'Идентификатор файла';


--
-- Name: COLUMN models_calculations_result_files.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_result_files.id_owner IS 'Владелец файла (он же создатель)';

--
-- Name: COLUMN models_calculations_result_files.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_result_files.created IS 'Когда создан файл (запись о нем в БД). Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_calculations_result_files.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_result_files.changed IS 'Когда изменен файл (запись о нем в БД). Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_calculations_result_files.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_result_files.changed_by IS 'Кем изменен файл (запись о нем в БД)';

--
-- Name: COLUMN models_calculations_result_files.id_mod_calc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_result_files.id_mod_calc IS 'Идентификатор расчета модели, которому принадлежит файл';

--
-- Name: COLUMN models_calculations_result_files.file_path; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_result_files.file_path IS 'Полный (абослютный) путь к файлу';








-- Таблица : Файлы с отчетами о расчетах моделей
--
-- Name: models_calculations_reports_files; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 51 (номер схемы: 51)
--

CREATE TABLE imc.models_calculations_reports_files (
    id_report_file uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_mod_calc  uuid NOT NULL,
    file_path  text NOT NULL,

    CONSTRAINT models_calculations_reports_files_1 UNIQUE (id_mod_calc, file_path)

);


ALTER TABLE imc.models_calculations_reports_files OWNER TO postgres;

--
-- Name: models_calculations_reports_files pk_models_calculations_reports_files; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.models_calculations_reports_files
    ADD CONSTRAINT pk_models_calculations_reports_files PRIMARY KEY (id_report_file);

--
-- Name: models_calculations_reports_files_id_report_file_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_models_calculations_reports_filesv_id_report_file_key ON imc.models_calculations_reports_files USING btree (id_report_file);


ALTER TABLE ONLY imc.models_calculations_reports_files
    ADD CONSTRAINT fk_models_calculations_reports_files_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_reports_files
    ADD CONSTRAINT fk_models_calculations_reports_files_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.models_calculations_reports_files
    ADD CONSTRAINT fk_models_calculations_reports_files_id_mod_calc FOREIGN KEY (id_mod_calc) REFERENCES imc.models_calculations(id_mod_calc);


--
-- Name: TABLE models_calculations_reports_files; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.models_calculations_reports_files IS 'Файлы с отчетами о расчетах моделей. Номер схемы: 51';


--
-- Name: COLUMN models_calculations_reports_files.id_report_file; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports_files.id_report_file IS 'Иеднтификатор файла';


--
-- Name: COLUMN models_calculations_reports_files.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports_files.id_owner IS 'Владелец файла (он же создатель)';

--
-- Name: COLUMN models_calculations_reports_files.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports_files.created IS 'Когда создан файл (запись о нем в БД). Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN models_calculations_reports_files.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports_files.changed IS 'Когда изменен файл (запись о нем в БД). Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN models_calculations_reports_files.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports_files.changed_by IS 'Кем изменен файл (запись о нем в БД).';

--
-- Name: COLUMN models_calculations_reports_files.id_mod_calc; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports_files.id_mod_calc IS 'Идентификатор расчета модели, которому принадлежит файл.';

--
-- Name: COLUMN models_calculations_reports_files.file_path; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.models_calculations_reports_files.file_path IS 'Полный (абослютный) путь к файлу.';





-- Таблица : СФЭ результирующих моделей
--
-- Name: resulting_models_sfes; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 52 (номер схемы: 52)
--

CREATE TABLE imc.resulting_models_sfes (
    id_sfe uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_res_model uuid NOT NULL,
    id_sfet uuid NOT NULL,
    vr_code text NOT NULL DEFAULT '(не задан)',

    CONSTRAINT resulting_models_sfes_1 UNIQUE (id_res_model, vr_code)


);


ALTER TABLE imc.resulting_models_sfes OWNER TO postgres;

--
-- Name: resulting_models_sfes pk_resulting_models_sfes; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.resulting_models_sfes
    ADD CONSTRAINT pk_resulting_models_sfes PRIMARY KEY (id_sfe);

--
-- Name: resulting_models_sfes_id_sfe_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_resulting_models_sfes_id_sfe_key ON imc.resulting_models_sfes USING btree (id_sfe);


ALTER TABLE ONLY imc.resulting_models_sfes
    ADD CONSTRAINT fk_resulting_models_sfes_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.resulting_models_sfes
    ADD CONSTRAINT fk_resulting_models_sfes_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.resulting_models_sfes
    ADD CONSTRAINT fk_resulting_models_sfes_id_res_model FOREIGN KEY (id_res_model) REFERENCES imc.resulting_models(id_res_model);


ALTER TABLE ONLY imc.resulting_models_sfes
    ADD CONSTRAINT fk_resulting_models_sfes_id_sfet FOREIGN KEY (id_sfet) REFERENCES imc.sfe_templates(id_sfet);


--
-- Name: TABLE resulting_models_sfes; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.resulting_models_sfes IS 'СФЭ результирующих моделей. Номер схемы: 52';


--
-- Name: COLUMN resulting_models_sfes.id_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfes.id_sfe IS 'Идентификатор СФЭ';


--
-- Name: COLUMN resulting_models_sfes.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfes.id_owner IS 'Владелец СФЭ (он же создатель)';

--
-- Name: COLUMN resulting_models_sfes.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfes.created IS 'Когда создан СФЭ . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN resulting_models_sfes.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfes.changed IS 'Когда изменен СФЭ . Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN resulting_models_sfes.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfes.changed_by IS 'Кем изменен СФЭ ';

--
-- Name: COLUMN resulting_models_sfes.id_res_model; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfes.id_res_model IS 'Идентификатор результирующей модели, которой принадлежит СФЭ';

--
-- Name: COLUMN resulting_models_sfes.id_sfet; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfes.id_sfet IS 'Идентификатор ШСФЭ, на основе которого создан СФЭ';

--
-- Name: COLUMN resulting_models_sfes.vr_code; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfes.vr_code IS 'Код визуального распознания СФЭ (уникален в пределах результирующей модели). Задается ИРЗ при создании ею результирующей модели.';








-- Таблица : Связи СФЭ результирующих моделей
--
-- Name: resulting_models_sfe_linkings; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 53 (номер схемы: 53)
--

CREATE TABLE imc.resulting_models_sfe_linkings (
    id_sfe_linking uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfe uuid NOT NULL,
    id_sfet_linking uuid NOT NULL,
    id_lmd_record uuid NOT NULL,
    id_ls_sfe uuid DEFAULT NULL,
    id_ls_aec_record uuid DEFAULT NULL,


    CONSTRAINT resulting_models_sfe_linkings_1 UNIQUE (id_sfe, id_sfet_linking, id_lmd_record, id_ls_sfe),
    CONSTRAINT resulting_models_sfe_linkings_2 UNIQUE (id_sfe, id_sfet_linking, id_lmd_record, id_ls_aec_record)


);


ALTER TABLE imc.resulting_models_sfe_linkings OWNER TO postgres;

--
-- Name: resulting_models_sfe_linkings pk_resulting_models_sfe_linkings; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.resulting_models_sfe_linkings
    ADD CONSTRAINT pk_resulting_models_sfe_linkings PRIMARY KEY (id_sfe_linking);

--
-- Name: resulting_models_sfe_linkings_id_sfe_linking_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_resulting_models_sfe_linkings_id_sfe_linking_key ON imc.resulting_models_sfe_linkings USING btree (id_sfe_linking);


ALTER TABLE ONLY imc.resulting_models_sfe_linkings
    ADD CONSTRAINT fk_resulting_models_sfe_linkings_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.resulting_models_sfe_linkings
    ADD CONSTRAINT fk_resulting_models_sfe_linkings_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.resulting_models_sfe_linkings
    ADD CONSTRAINT fk_resulting_models_sfe_linkings_id_sfe FOREIGN KEY (id_sfe) REFERENCES imc.resulting_models_sfes(id_sfe);


ALTER TABLE ONLY imc.resulting_models_sfe_linkings
    ADD CONSTRAINT fk_resulting_models_sfe_linkings_id_sfet_linking FOREIGN KEY (id_sfet_linking) REFERENCES imc.sfet_linkings(id_sfet_linking);


ALTER TABLE ONLY imc.resulting_models_sfe_linkings
    ADD CONSTRAINT fk_resulting_models_sfe_linkings_id_lmd_record FOREIGN KEY (id_lmd_record) REFERENCES imc.dc_records(id_record);


ALTER TABLE ONLY imc.resulting_models_sfe_linkings
    ADD CONSTRAINT fk_resulting_models_sfe_linkings_id_ls_sfe FOREIGN KEY (id_ls_sfe) REFERENCES imc.resulting_models_sfes(id_sfe);


ALTER TABLE ONLY imc.resulting_models_sfe_linkings
    ADD CONSTRAINT fk_resulting_models_sfe_linkings_id_ls_aec_record FOREIGN KEY (id_ls_aec_record) REFERENCES imc.dc_records(id_record);



--
-- Name: TABLE resulting_models_sfe_linkings; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.resulting_models_sfe_linkings IS 'Связи СФЭ результирующих моделей. Номер схемы: 53';


--
-- Name: COLUMN resulting_models_sfe_linkings.id_sfe_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_linkings.id_sfe_linking IS 'Идентификатор связи СФЭ';


--
-- Name: COLUMN resulting_models_sfe_linkings.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_linkings.id_owner IS 'Владелец связи СФЭ (он же создатель)';

--
-- Name: COLUMN resulting_models_sfe_linkings.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_linkings.created IS 'Когда создана связь СФЭ. Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN resulting_models_sfe_linkings.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_linkings.changed IS 'Когда изменена связь СФЭ. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN resulting_models_sfe_linkings.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_linkings.changed_by IS 'Кем изменена связь СФЭ.';


--
-- Name: COLUMN resulting_models_sfe_linkings.id_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_linkings.id_sfe IS 'Идентификатор СФЭ, которому принадлежит связь';

--
-- Name: COLUMN resulting_models_sfe_linkings.id_sfet_linking; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_linkings.id_sfet_linking IS 'Идентификатор связи ШСФЭ, по которой создана связь СФЭ';

--
-- Name: COLUMN resulting_models_sfe_linkings.id_lmd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_linkings.id_lmd_record IS 'Идентификатор записи семантики связи';

--
-- Name: COLUMN resulting_models_sfe_linkings.id_ls_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_linkings.id_ls_sfe IS 'Идентификатор СФЭ-субъекта связи';

--
-- Name: COLUMN resulting_models_sfe_linkings.id_ls_aec_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_linkings.id_ls_aec_record IS 'Идентификатор записи каталога иных сущностей-субъекта связи';







-- Таблица : Свойства СФЭ результирующих моделей 
--
-- Name: resulting_models_sfe_properties; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 54 (номер схемы: 54)
--

CREATE TABLE imc.resulting_models_sfe_properties (
    id_sfe_property uuid UNIQUE NOT NULL,

    id_owner uuid NOT NULL,
    created timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    changed_by uuid NOT NULL,

    id_sfe uuid NOT NULL,
    id_sfet_property uuid NOT NULL,

    val text DEFAULT NULL,
    val_by_id_pvd_record uuid DEFAULT NULL

);


ALTER TABLE imc.resulting_models_sfe_properties OWNER TO postgres;

--
-- Name: resulting_models_sfe_properties pk_resulting_models_sfe_properties; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.resulting_models_sfe_properties
    ADD CONSTRAINT pk_resulting_models_sfe_properties PRIMARY KEY (id_sfe_property);

--
-- Name: resulting_models_sfe_properties_id_sfe_property_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_resulting_models_sfe_properties_id_sfe_property_key ON imc.resulting_models_sfe_properties USING btree (id_sfe_property);


ALTER TABLE ONLY imc.resulting_models_sfe_properties
    ADD CONSTRAINT fk_resulting_models_sfe_properties_id_owner FOREIGN KEY (id_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.resulting_models_sfe_properties
    ADD CONSTRAINT fk_resulting_models_sfe_properties_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.resulting_models_sfe_properties
    ADD CONSTRAINT fk_resulting_models_sfe_properties_id_sfe FOREIGN KEY (id_sfe) REFERENCES imc.resulting_models_sfes(id_sfe);


ALTER TABLE ONLY imc.resulting_models_sfe_properties
    ADD CONSTRAINT fk_resulting_models_sfe_properties_id_sfet_property FOREIGN KEY (id_sfet_property) REFERENCES imc.sfet_properties(id_sfet_property);


ALTER TABLE ONLY imc.resulting_models_sfe_properties
    ADD CONSTRAINT fk_resulting_models_sfe_properties_val_by_id_pvd_record FOREIGN KEY (val_by_id_pvd_record) REFERENCES imc.dc_records(id_record);


--
-- Name: TABLE resulting_models_sfe_properties; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.resulting_models_sfe_properties IS 'Свойства СФЭ результирующих моделей. Номер схемы: 54';


--
-- Name: COLUMN resulting_models_sfe_properties.id_sfe_property; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_properties.id_sfe_property IS 'Идентификатор свойства СФЭ';


--
-- Name: COLUMN resulting_models_sfe_properties.id_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_properties.id_owner IS 'Владелец свойства СФЭ (он же создатель)';

--
-- Name: COLUMN resulting_models_sfe_properties.created; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_properties.created IS 'Когда создано свойство СФЭ . Значение по умолчанию - now() по триггеру INSERT.';

--
-- Name: COLUMN resulting_models_sfe_properties.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_properties.changed IS 'Когда изменено свойство СФЭ . Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN resulting_models_sfe_properties.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_properties.changed_by IS 'Кем изменено свойство СФЭ';


--
-- Name: COLUMN resulting_models_sfe_properties.id_sfe; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_properties.id_sfe IS 'Идентификатор СФЭ, которому принадлежит свойство СФЭ';

--
-- Name: COLUMN resulting_models_sfe_properties.id_sfet_property; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_properties.id_sfet_property IS 'Идентификатор свойства ШСФЭ, по которому создано свойство СФЭ';

--
-- Name: COLUMN resulting_models_sfe_properties.val; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_properties.val IS 'Значение свойства СФЭ';

--
-- Name: COLUMN resulting_models_sfe_properties.val_by_id_pvd_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.resulting_models_sfe_properties.val_by_id_pvd_record IS 'Идентификатор записи словаря возможных значений, если значение свойства СФЭ является записью из этого словаря';








-- Таблица : Истории изменений тематических срезов и моделей
--
-- Name: changing_history; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 55 (номер схемы: 55)
--

CREATE TABLE imc.changing_history (
    id_changing uuid UNIQUE NOT NULL,

    id_layer uuid DEFAULT NULL,
    id_model uuid DEFAULT NULL,
    changed timestamp without time zone NOT NULL,
    changed_by uuid NOT NULL

);


ALTER TABLE imc.changing_history OWNER TO postgres;

--
-- Name: changing_history pk_changing_history; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.changing_history
    ADD CONSTRAINT pk_changing_history PRIMARY KEY (id_changing);

--
-- Name: changing_history_id_changing_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_changing_history_id_changing_key ON imc.changing_history USING btree (id_changing);


ALTER TABLE ONLY imc.changing_history
    ADD CONSTRAINT fk_changing_history_id_layer FOREIGN KEY (id_layer) REFERENCES imc.thematic_layers(id_layer);


ALTER TABLE ONLY imc.changing_history
    ADD CONSTRAINT fk_changing_history_id_model FOREIGN KEY (id_model) REFERENCES imc.models(id_model);


ALTER TABLE ONLY imc.changing_history
    ADD CONSTRAINT fk_changing_history_changed_by FOREIGN KEY (changed_by) REFERENCES imc.users(id_user);


--
-- Name: TABLE changing_history; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.changing_history IS 'Истории изменений тематических срезов и моделей. Номер схемы: 55';


--
-- Name: COLUMN changing_history.id_id_changing; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.changing_history.id_changing IS 'Идентификатор записи об изменении';


--
-- Name: COLUMN changing_history.id_layer; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.changing_history.id_layer IS 'Идентификатор тематического среза, который был изменен';

--
-- Name: COLUMN changing_history.id_model; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.changing_history.id_model IS 'Идентификатор модели, которая была изменена';


--
-- Name: COLUMN changing_history.changed; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.changing_history.changed IS 'Когда было выполнено изменение. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN changing_history.changed_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.changing_history.changed_by IS 'Кем было выполнено изменение';






-- Таблица : Фильтры представлений тематических срезов, моделей и результирующих моделей
--
-- Name: presentations_filters; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 56 (номер схемы: 56)
--

CREATE TABLE imc.presentations_filters (
    id_filter uuid UNIQUE NOT NULL,

    id_layer uuid DEFAULT NULL,
    id_model uuid DEFAULT NULL,
    id_res_model uuid DEFAULT NULL,
    saved timestamp without time zone NOT NULL DEFAULT date_trunc('second'::text, now()),
    saved_by uuid NOT NULL,

    c1_sfe_kind_name text DEFAULT NULL,
    c1_sfet_name text DEFAULT NULL,
    c1_sfe_vr_code text DEFAULT NULL,
    c1_sfe_property_name text DEFAULT NULL,
    c1_sfe_property_val text DEFAULT NULL,

    c2_sfe_kind_name text DEFAULT NULL,
    c2_sfet_name text DEFAULT NULL,
    c2_sfe_vr_code text DEFAULT NULL,
    c2_sfe_property_name text DEFAULT NULL,
    c2_sfe_property_val text DEFAULT NULL,
    c2_lm_name text DEFAULT NULL,
    c2_aec_record_name text DEFAULT NULL

);


ALTER TABLE imc.presentations_filters OWNER TO postgres;

--
-- Name: presentations_filters pk_presentations_filters; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.presentations_filters
    ADD CONSTRAINT pk_presentations_filters PRIMARY KEY (id_filter);

--
-- Name: presentations_filters_id_filter_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_presentations_filters_id_filter_key ON imc.presentations_filters USING btree (id_filter);


ALTER TABLE ONLY imc.presentations_filters
    ADD CONSTRAINT fk_presentations_filters_id_layer FOREIGN KEY (id_layer) REFERENCES imc.thematic_layers(id_layer);


ALTER TABLE ONLY imc.presentations_filters
    ADD CONSTRAINT fk_presentations_filters_id_model FOREIGN KEY (id_model) REFERENCES imc.models(id_model);


ALTER TABLE ONLY imc.presentations_filters
    ADD CONSTRAINT fk_presentations_filters_id_res_model FOREIGN KEY (id_res_model) REFERENCES imc.resulting_models(id_res_model);


ALTER TABLE ONLY imc.presentations_filters
    ADD CONSTRAINT fk_presentations_filters_saved_by FOREIGN KEY (saved_by) REFERENCES imc.users(id_user);


--
-- Name: TABLE presentations_filters; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.presentations_filters IS 'Фильтры представлений тематических срезов, моделей и результирующих моделей. Номер схемы: 56';


--
-- Name: COLUMN presentations_filters.id_filter; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.id_filter IS 'Идентификатор сохраненного фильтра';


--
-- Name: COLUMN presentations_filters.id_layer; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.id_layer IS 'Идентификатор тематического среза, для которого сохранен фильтр';

--
-- Name: COLUMN presentations_filters.id_model; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.id_model IS 'Идентификатор модели, для которой сохранен фильтр';

--
-- Name: COLUMN presentations_filters.id_res_model; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.id_res_model IS 'Идентификатор результирующей модели, для которой сохранен фильтр';

--
-- Name: COLUMN presentations_filters.saved; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.saved IS 'Когда сохранен фильтр. Значение по умолчанию - now() по триггеру UPDATE.';

--
-- Name: COLUMN presentations_filters.saved_by; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.saved_by IS 'Кем сохранен фильтр.';


--
-- Name: COLUMN presentations_filters.c1_sfe_kind_name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c1_sfe_kind_name IS 'Колонка 1. Маска названия вида СФЭ';

--
-- Name: COLUMN presentations_filters.c1_sfet_name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c1_sfet_name IS 'Колонка 1. Маска названия шаблона СФЭ';

--
-- Name: COLUMN presentations_filters.c1_sfe_vr_code; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c1_sfe_vr_code IS 'Колонка 1. Маска кода визуального распознания СФЭ';

--
-- Name: COLUMN presentations_filters.c1_sfe_property_name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c1_sfe_property_name IS 'Колонка 1. Маска названия свойства СФЭ';

--
-- Name: COLUMN presentations_filters.c1_sfe_property_val; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c1_sfe_property_val IS 'Колонка 1. Маска значения свойства СФЭ';

--
-- Name: COLUMN presentations_filters.c2_sfe_kind_name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c2_sfe_kind_name IS 'Колонка 2. Маска названия вида СФЭ';

--
-- Name: COLUMN presentations_filters.c2_sfet_name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c2_sfet_name IS 'Колонка 2. Маска названия шаблона СФЭ';

--
-- Name: COLUMN presentations_filters.c2_sfe_vr_code; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c2_sfe_vr_code IS 'Колонка 2. Маска кода визуального распознания СФЭ';

--
-- Name: COLUMN presentations_filters.c2_sfe_property_name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c2_sfe_property_name IS 'Колонка 2. Маска названия свойства СФЭ';

--
-- Name: COLUMN presentations_filters.c2_sfe_property_val; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c2_sfe_property_val IS 'Колонка 2. Маска значения свойства СФЭ';

--
-- Name: COLUMN presentations_filters.c2_lm_name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c2_lm_name IS 'Колонка 2. Маска семантики связи СФЭ';

--
-- Name: COLUMN presentations_filters.c2_aec_record_name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.presentations_filters.c2_aec_record_name IS 'Колонка 2. Маска названия иной от СФЭ сущности-субъекта связи СФЭ';









-- Таблица : Роли
--
-- Name: roles; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 58 (номер схемы: 58)
--

CREATE TABLE imc.roles (
    id_role uuid UNIQUE NOT NULL,

    name text NOT NULL,
    note text DEFAULT NULL,

    order_in_list integer UNIQUE NOT NULL

);


ALTER TABLE imc.roles OWNER TO postgres;

--
-- Name: roles pk_roles; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.roles
    ADD CONSTRAINT pk_roles PRIMARY KEY (id_role);

--
-- Name: roles_id_role_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_roles_id_role_key ON imc.roles USING btree (id_role);



--
-- Name: TABLE roles; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.roles IS 'Роли. Номер схемы: 58';


--
-- Name: COLUMN roles.id_role; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles.id_role IS 'Идентификатор роли';


--
-- Name: COLUMN roles.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles.name IS 'Название роли';

--
-- Name: COLUMN roles.note; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles.note IS 'Заметка о роли';

--
-- Name: COLUMN roles.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles.order_in_list IS 'Порядковый номер (номер позиции) роли в списке ролей (нужен для организации web-интерфейсов). Значение: от 1 до N, по триггеру INSERT';



INSERT INTO imc.roles (id_role, name, note, order_in_list) 
VALUES ('d84d96ef-457d-4197-a74e-ca3c3ac3cec9', 'Администратор доступа', NULL, 1);

INSERT INTO imc.roles (id_role, name, note, order_in_list) 
VALUES ('a65b8804-f5ee-484e-9bd4-52b24f403453', 'Администратор схем (и их информационных моделей)', NULL, 2);

INSERT INTO imc.roles (id_role, name, note, order_in_list) 
VALUES ('d053b9c4-83c5-4c82-ad28-442580fc4b7f', 'Администратор ИРЗ', NULL, 3);

INSERT INTO imc.roles (id_role, name, note, order_in_list) 
VALUES ('554f5b59-edcb-4307-91e7-446c4767f0f5', 'Пользователь', NULL, 4);






-- Таблица : Роли пользователей
--
-- Name: users_roles; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 59 (номер схемы: 59)
--

CREATE TABLE imc.users_roles (
    id_record uuid UNIQUE NOT NULL,

    id_user uuid NOT NULL,
    id_role uuid NOT NULL,


    CONSTRAINT users_roles_1 UNIQUE (id_user, id_role)

);


ALTER TABLE imc.users_roles OWNER TO postgres;

--
-- Name: users_roles pk_users_roles; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.users_roles
    ADD CONSTRAINT pk_users_roles PRIMARY KEY (id_record);

--
-- Name: roles_id_record_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_users_roles_id_record_key ON imc.users_roles USING btree (id_record);


ALTER TABLE ONLY imc.users_roles
    ADD CONSTRAINT fk_users_roles_id_user FOREIGN KEY (id_user) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.users_roles
    ADD CONSTRAINT fk_users_roles_id_role FOREIGN KEY (id_role) REFERENCES imc.roles(id_role);



--
-- Name: TABLE users_roles; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.users_roles IS 'Роли пользователей. Номер схемы: 59';


--
-- Name: COLUMN users_roles.id_record; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users_roles.id_record IS 'Идентификатор записи таблицы';

--
-- Name: COLUMN users_roles.id_user; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users_roles.id_user IS 'Идентификатор пользователя, которому присвоена роль';

--
-- Name: COLUMN users_roles.id_role; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users_roles.id_role IS 'Идентификатор роли, присвоенной пользователю';







-- Таблица : Виды объектов доступа
--
-- Name: access_objects_kinds; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 60 (номер схемы: 60)
--

CREATE TABLE imc.access_objects_kinds (
    id_acc_obj_kind uuid UNIQUE NOT NULL,

    name text UNIQUE NOT NULL,
    note text DEFAULT NULL,

    order_in_list integer UNIQUE NOT NULL

);


ALTER TABLE imc.access_objects_kinds OWNER TO postgres;

--
-- Name: access_objects_kinds pk_access_objects_kinds; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.access_objects_kinds
    ADD CONSTRAINT pk_access_objects_kinds PRIMARY KEY (id_acc_obj_kind);

--
-- Name: access_objects_kinds_id_acc_obj_kind_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_access_objects_kinds_id_acc_obj_kind_key ON imc.access_objects_kinds USING btree (id_acc_obj_kind);



--
-- Name: TABLE access_objects_kinds; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.access_objects_kinds IS 'Виды объектов доступа. Номер схемы: 60';


--
-- Name: COLUMN access_objects_kinds.id_acc_obj_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.access_objects_kinds.id_acc_obj_kind IS 'Идентификатор вида объекта доступа';


--
-- Name: COLUMN access_objects_kinds.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.access_objects_kinds.name IS 'Название вида объекта доступа';

--
-- Name: COLUMN access_objects_kinds.note; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.access_objects_kinds.note IS 'Заметка о виде объекта доступа';

--
-- Name: COLUMN access_objects_kinds.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.access_objects_kinds.order_in_list IS 'Порядковый номер (номер позиции) вида объекта доступа в списке видов объекта доступа (нужен для организации web-интерфейсов). Значение: от 1 до N, по триггеру INSERT';


INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('1f70eebe-eeca-492d-88c4-b6d63391f68b', 'Схема', NULL, 1);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('ff9f006a-c7aa-4bf3-904d-3d0003ea66f7', 'Группа тематических срезов', NULL, 2);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('9a3c0aaa-6826-45a5-8649-d5ae805fc257', 'Тематический срез', NULL, 3);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('45e12eee-b45b-45d6-89aa-46c0cafb506e', 'Группа видов СФЭ', NULL, 4);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('a23cc9c6-f498-4797-8175-056e5d05b349', 'Вид СФЭ', NULL, 5);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('7bc65038-96de-4e53-9b7d-ec8d688f291e', 'Словарь/Каталог', NULL, 6);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('c88f962b-04df-4af2-a1f4-a0aa969643e8', 'Запись словаря/каталога', NULL, 7);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('ec79c541-8436-4511-9551-f808c1344fef', 'Шаблон СФЭ', NULL, 8);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('94c5351b-3120-4bbb-b814-0c532ba68377', 'Группа связей шаблона СФЭ', NULL, 9);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('fbe51d36-ff11-40de-a863-b9e25e778065', 'Связь шаблона СФЭ', NULL, 10);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('e6721f89-9e06-401b-a694-df40487a892c', 'Группа свойств шаблона СФЭ', NULL, 11);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('38846ace-e9ae-494b-a16f-df9c0483d1e7', 'Свойство шаблона СФЭ', NULL, 12);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('55b609a3-50dc-49fd-9486-6b9e97ef23af', 'СФЭ тематического среза', NULL, 13);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('5e00cc42-32a4-4492-8442-eff261dbda97', 'Связь СФЭ тематического среза', NULL, 14);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('dea5adae-e37b-437c-bfbc-54bc7ea80bfd', 'Свойство СФЭ тематического среза', NULL, 15);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('d6060e4a-492c-42e8-9953-eb563158a41f', 'ИРЗ', NULL, 16);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('1fd664dd-322b-4110-9fbd-fb2e05f0c836', 'Целевой показатель ИРЗ', NULL, 17);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('e484eda6-a7a3-440e-935c-380484c80b67', 'Команда запуска ИРЗ в ОС', NULL, 18);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('aa04d53e-0403-47a8-8d32-768794fb8084', 'Папка обмена данными с ИРЗ', NULL, 19);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('60b1d3e5-62aa-4285-b935-00a20c0e1652', 'Вид СФЭ ИРЗ', NULL, 20);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('231b67a4-47f9-4e80-8b75-5ab9aef85da5', 'Шаблон СФЭ ИРЗ', NULL, 21);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('fd549ac8-25cf-4808-b655-70def26fbcab', 'Связь шаблона СФЭ ИРЗ', NULL, 22);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('7e22814b-edee-4f26-8427-77546c66d0ab', 'Свойство шаблона СФЭ ИРЗ', NULL, 23);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('fc8d2fa2-a2f3-412b-be6d-6991a47c3b77', 'Словарь/каталог ИРЗ', NULL, 24);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('fa303139-356e-42f7-a229-d730dfa06e9b', 'Запись словаря/каталога ИРЗ', NULL, 25);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('5f48e1bf-71e2-4b9d-9ac5-2f6b1370ae64', 'Конфигурационный параметр ИРЗ', NULL, 26);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('37d268f9-80c1-43d0-b46e-2aa48ff1d431', 'Группа моделей', NULL, 27);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('68d57891-6276-4011-aff3-758d6af847d9', 'Модель', NULL, 28);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('a72585c6-9b3c-4a02-be94-d6901065fc67', 'СФЭ модели', NULL, 29);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('be1018d5-b463-4e71-b15c-0c61e5d1b971', 'Связь СФЭ модели', NULL, 30);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('e8304594-4b97-4b08-80cf-d89821989421', 'Свойство СФЭ модели', NULL, 31);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('f8875044-ab58-487c-aecd-95c5e5fe2909', 'Расчет модели', NULL, 32);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('0974a049-ac13-4ff3-8a19-1c9be7433128', 'Правило расчета модели', NULL, 33);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('6ca08689-182b-4606-8d24-b9c75dfb1f9f', 'Целевой показатель расчета модели', NULL, 34);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('6b9c10c8-898f-40f9-803c-fe0a0dcc9a56', 'Конфигурационный параметр ИРЗ для расчета модели', NULL, 35);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('82b2c00d-b5c8-46ce-ba6e-d868151f052d', 'Результирующая модель', NULL, 36);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('46f237ec-527b-4a03-914c-629e1f3e4980', 'Отчет о расчете модели', NULL, 37);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('5e23aeb5-2e22-4772-be6b-3f46be97b34b', 'Файл с результатами расчета модели', NULL, 38);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('ae8fcd73-2fbf-41bd-a41e-bde5f79b7d5c', 'Файл с отчетом о расчете модели', NULL, 39);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('33b16dd8-820b-49a0-88b1-0046846c2a05', 'СФЭ результирующей модели', NULL, 40);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('f6d50521-4294-4fc8-93f8-2ae54f66f632', 'Связь СФЭ результирующей модели', NULL, 41);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('b3ad2d00-1bf8-40e9-947a-891965e2f321', 'Свойство СФЭ результирующей модели', NULL, 42);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('7cf1d8da-8ff5-4750-adbc-3fac99fe9ac4', 'Запись истории изменений тематических срезов', NULL, 43);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('e9c2cf63-766d-423b-9a7c-e58c662583dd', 'Запись истории изиенений моделей', NULL, 44);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('3e118647-cc0c-45d6-841f-9d2a204105b5', 'Сохраненный фильтр представлений тематических срезов', NULL, 45);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('afa429e2-1788-4d2b-8678-b7846887870e', 'Сохраненный фильтр представлений моделей', NULL, 46);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('a34c6387-d6b9-413c-9ff8-16e46f96f635', 'Сохраненный фильтр представлений результирующих моделей', NULL, 47);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('dc4958e8-0eee-4427-a997-cfded6eb7396', 'Вхождение тематического среза в группы тематических срезов', NULL, 48);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('2adba1df-0a41-485c-9c8f-85424ae3c26f', 'Вхождение вида СФЭ в группы видов СФЭ', NULL, 49);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('e83d8910-f19e-44e9-8f1d-2f0839b5b756', 'Вхождение модели в группы моделей', NULL, 50);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('f8dc4754-9b67-4783-95ba-9aa243b4905e', 'Пользователь', NULL, 51);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('cfa87383-bf23-4764-9d41-01383dc4c15e', 'Роль', NULL, 52);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('50659e2e-55dd-48cd-8044-55901089adf7', 'Роль пользователя', NULL, 53);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('94577260-48a1-4a0d-8344-08cbd4afe67f', 'Право роли на действие с объектов доступа', NULL, 54);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('271242a7-950a-4b16-b8f9-d39a6d34aafd', 'Право, делегированное пользователю владельцем объекта доступа', NULL, 55);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('22387ad1-8014-4ec5-b3c1-df407fb6004b', 'Вид объекта доступа', NULL, 56);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('09d59eb4-61d4-435c-a6db-9bfb60434c45', 'Вид действия с объектом доступа', NULL, 57);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('34593800-21d1-4af9-b51c-55601a0eadeb', 'Вид словаря/каталога', NULL, 58);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('6e0734f6-2100-412b-a9e6-7b0d34393a92', 'Вид субъекта связи шаблона СФЭ', NULL, 59);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('e42fa12d-e003-4773-a736-da003bd79d30', 'Тип значения свойства шаблона СФЭ', NULL, 60);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('52389195-f88e-4f95-ab40-9bd6b3de92ed', 'Вид правила расчета ИРЗ', NULL, 61);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('e47b7df7-6737-4cf0-8010-5cb8059911d3', 'Допустимая комбинация операндов правила расчета ИРЗ', NULL, 62);

INSERT INTO imc.access_objects_kinds (id_acc_obj_kind, name, note, order_in_list) 
VALUES ('e13f3f04-109d-47ce-b732-91022a0ef0d9', 'Тип значения конфигурационного параметра ИРЗ', NULL, 63);






-- Таблица : Виды действий с объектами доступа
--
-- Name: access_objects_acts_kinds; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 61 (номер схемы: 61)
--

CREATE TABLE imc.access_objects_acts_kinds (
    id_acc_obj_act_kind uuid UNIQUE NOT NULL,

    name text UNIQUE NOT NULL,
    is_can_be_delegated boolean DEFAULT TRUE,
    note text DEFAULT NULL,

    order_in_list integer NOT NULL

);


ALTER TABLE imc.access_objects_acts_kinds OWNER TO postgres;

--
-- Name: access_objects_acts_kinds pk_access_objects_acts_kinds; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.access_objects_acts_kinds
    ADD CONSTRAINT pk_access_objects_acts_kinds PRIMARY KEY (id_acc_obj_act_kind);

--
-- Name: access_objects_acts_kinds_id_acc_obj_act_kind_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_access_objects_acts_kinds_id_acc_obj_act_kind_key ON imc.access_objects_acts_kinds USING btree (id_acc_obj_act_kind);



--
-- Name: TABLE access_objects_acts_kinds; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.access_objects_acts_kinds IS 'Виды действий с объектами доступа. Номер схемы: 61';


--
-- Name: COLUMN access_objects_acts_kinds.id_acc_obj_act_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.access_objects_acts_kinds.id_acc_obj_act_kind IS 'Идентификатор вида действия с объектом доступа';

--
-- Name: COLUMN access_objects_acts_kinds.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.access_objects_acts_kinds.name IS 'Название вида действия с объектом доступа';

--
-- Name: COLUMN access_objects_acts_kinds.is_can_be_delegated; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.access_objects_acts_kinds.is_can_be_delegated IS 'Может ли вид действия с объектом доступа быть делегирован в качестве права пользователю владельцем объекта доступа';


--
-- Name: COLUMN access_objects_acts_kinds.note; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.access_objects_acts_kinds.note IS 'Заметка о виде действия с объектом доступа';

--
-- Name: COLUMN access_objects_acts_kinds.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.access_objects_acts_kinds.order_in_list IS 'Порядковый номер (номер позиции) вида действия с объектом доступа в списке видов действий с объектами доступа (нужен для организации web-интерфейсов). Значение: от 1 до N, по триггеру INSERT';



INSERT INTO imc.access_objects_acts_kinds (id_acc_obj_act_kind, name, is_can_be_delegated, note, order_in_list) 
VALUES ('e24477d2-0c83-4f95-91bb-c0eba4cb5945', 'Просмотреть', TRUE, NULL, 1);

INSERT INTO imc.access_objects_acts_kinds (id_acc_obj_act_kind, name, is_can_be_delegated, note, order_in_list) 
VALUES ('94a776e0-a07e-47e7-9715-f8d1e456d93c', 'Добавить', TRUE, NULL, 2);

INSERT INTO imc.access_objects_acts_kinds (id_acc_obj_act_kind, name, is_can_be_delegated, note, order_in_list) 
VALUES ('484919be-1345-41a5-960e-b204b6b88ab6', 'Изменить', TRUE, NULL, 3);

INSERT INTO imc.access_objects_acts_kinds (id_acc_obj_act_kind, name, is_can_be_delegated, note, order_in_list) 
VALUES ('29378248-04b2-45f6-b8cc-af10cae52932', 'Удалить', TRUE, NULL, 4);

INSERT INTO imc.access_objects_acts_kinds (id_acc_obj_act_kind, name, is_can_be_delegated, note, order_in_list) 
VALUES ('559f5429-9768-409f-9460-6e8600f9dd81', 'Импортировать', TRUE, NULL, 5);

INSERT INTO imc.access_objects_acts_kinds (id_acc_obj_act_kind, name, is_can_be_delegated, note, order_in_list) 
VALUES ('8db297e3-060f-4f87-b121-dbe25bc2cf9b', 'Экспортировать', TRUE, NULL, 6);

INSERT INTO imc.access_objects_acts_kinds (id_acc_obj_act_kind, name, is_can_be_delegated, note, order_in_list) 
VALUES ('ed65f7d0-7829-431e-b2ea-1eb959bda05c', 'Рассчитать', TRUE, NULL, 7);

INSERT INTO imc.access_objects_acts_kinds (id_acc_obj_act_kind, name, is_can_be_delegated, note, order_in_list) 
VALUES ('d97a6084-2628-44c5-ad7e-adb6e707a88e', 'Копировать в буфер обмена', TRUE, NULL, 8);

INSERT INTO imc.access_objects_acts_kinds (id_acc_obj_act_kind, name, is_can_be_delegated, note, order_in_list) 
VALUES ('13e77c11-582f-41b9-9dec-e1928d9f56f4', 'Вставить из буфера обмена', TRUE, NULL, 9);





-- Таблица : Допустимые действия с объектами доступа
--
-- Name: allowed_access_objects_acts; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 62 (номер схемы: 62)
--

CREATE TABLE imc.allowed_access_objects_acts (
    id_allowed_act uuid UNIQUE NOT NULL,

    id_acc_obj_kind uuid NOT NULL,
    id_acc_obj_act_kind uuid NOT NULL,

    apply_to_all_like_objs boolean DEFAULT TRUE,
    note text DEFAULT NULL,

    order_in_list integer UNIQUE NOT NULL,

    CONSTRAINT allowed_access_objects_acts_1 UNIQUE (id_acc_obj_kind, id_acc_obj_act_kind)

);


ALTER TABLE imc.allowed_access_objects_acts OWNER TO postgres;

--
-- Name: allowed_access_objects_acts pk_allowed_access_objects_acts; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.allowed_access_objects_acts
    ADD CONSTRAINT pk_allowed_access_objects_acts PRIMARY KEY (id_allowed_act);

--
-- Name: allowed_access_objects_acts_id_allowed_act_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_allowed_access_objects_acts_id_allowed_act_key ON imc.allowed_access_objects_acts USING btree (id_allowed_act);


ALTER TABLE ONLY imc.allowed_access_objects_acts
    ADD CONSTRAINT fk_allowed_access_objects_acts_id_acc_obj_kind FOREIGN KEY (id_acc_obj_kind) REFERENCES imc.access_objects_kinds(id_acc_obj_kind);


ALTER TABLE ONLY imc.allowed_access_objects_acts
    ADD CONSTRAINT fk_allowed_access_objects_acts_id_acc_obj_act_kind FOREIGN KEY (id_acc_obj_act_kind) REFERENCES imc.access_objects_acts_kinds(id_acc_obj_act_kind);


--
-- Name: TABLE allowed_access_objects_acts; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.allowed_access_objects_acts IS 'Допустимые действия с объектами доступа. Номер схемы: 62';


--
-- Name: COLUMN allowed_access_objects_acts.id_allowed_act; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.allowed_access_objects_acts.id_allowed_act IS 'Идентификатор допустимого действия с объектом доступа';


--
-- Name: COLUMN allowed_access_objects_acts.id_acc_obj_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.allowed_access_objects_acts.id_acc_obj_kind IS 'Идентификатор вида объекта доступа, с которым допустим вид действия';

--
-- Name: COLUMN allowed_access_objects_acts.id_acc_obj_act_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.allowed_access_objects_acts.id_acc_obj_act_kind IS 'Идентификатор вида действия, которое допустимо с видом объекта доступа';


--
-- Name: COLUMN allowed_access_objects_acts.apply_to_all_like_objs; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.allowed_access_objects_acts.apply_to_all_like_objs IS 'Применять ли действие ко всем объектам доступа, имеющим вид, заданный полем id_acc_obj_kind';


--
-- Name: COLUMN allowed_access_objects_acts.note; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.allowed_access_objects_acts.note IS 'Заметка о допустимом действии с объектом доступа';


--
-- Name: COLUMN allowed_access_objects_acts.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.allowed_access_objects_acts.order_in_list IS 'Порядковый номер (номер позиции) допустимого действия в списке допустимых действий с объектами доступа (нужен для организации web-интерфейсов). Значение: от 1 до N, по триггеру INSERT';







-- Таблица : Права ролей на действия с объектами доступа
--
-- Name: roles_rights; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 63 (номер схемы: 63)
--

CREATE TABLE imc.roles_rights (
    id_right uuid UNIQUE NOT NULL,

    id_role uuid NOT NULL,
    id_allowed_act uuid NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT roles_rights_1 UNIQUE (id_role, id_allowed_act),
    CONSTRAINT roles_rights_2 UNIQUE (id_role, order_in_list)

);


ALTER TABLE imc.roles_rights OWNER TO postgres;

--
-- Name: roles_rights pk_roles_rights; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.roles_rights
    ADD CONSTRAINT pk_roles_rights PRIMARY KEY (id_right);

--
-- Name: roles_id_right_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_roles_rights_id_right_key ON imc.roles_rights USING btree (id_right);


ALTER TABLE ONLY imc.roles_rights
    ADD CONSTRAINT fk_roles_rights_id_role FOREIGN KEY (id_role) REFERENCES imc.roles(id_role);


ALTER TABLE ONLY imc.roles_rights
    ADD CONSTRAINT fk_roles_rights_id_allowed_act FOREIGN KEY (id_allowed_act) REFERENCES imc.allowed_access_objects_acts(id_allowed_act);



--
-- Name: TABLE roles_rights; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.roles_rights IS 'Права ролей на действия с объектами доступа. Номер схемы: 63';


--
-- Name: COLUMN roles_rights.id_right; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles_rights.id_right IS 'Идентификатор права роли';

--
-- Name: COLUMN roles_rights.id_role; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles_rights.id_role IS 'Идентификатор роли, которой предоставлено право';

--
-- Name: COLUMN roles_rights.id_allowed_act; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles_rights.id_allowed_act IS 'Идентификатор действия, которое предоставлено роли в качестве права';

--
-- Name: COLUMN roles_rights.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles_rights.order_in_list IS 'Порядковый номер (номер позиции) прав роли в списке прав одной роли (нужен для организации web-интерфейсов). Значение: от 1 до N, по триггеру INSERT';











-- Таблица : Права, делегированные пользователям владельцами объектов доступа
--
-- Name: users_delegated_rights; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 64 (номер схемы: 64)
--

CREATE TABLE imc.users_delegated_rights (
    id_right uuid UNIQUE NOT NULL,

    id_from_owner uuid NOT NULL,
    id_user uuid NOT NULL,
    id_allowed_act uuid NOT NULL,
    id_allowed_acc_obj uuid NOT NULL,

    order_in_list integer NOT NULL,

    CONSTRAINT users_delegated_rights_1 UNIQUE (id_user, id_allowed_act, id_allowed_acc_obj),
    CONSTRAINT users_delegated_rights_2 UNIQUE (id_user, id_allowed_act, order_in_list)

);


ALTER TABLE imc.users_delegated_rights OWNER TO postgres;

--
-- Name: users_delegated_rights pk_users_delegated_rights; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.users_delegated_rights
    ADD CONSTRAINT pk_users_delegated_rights PRIMARY KEY (id_right);

--
-- Name: roles_id_right_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_users_delegated_rights_id_right_key ON imc.users_delegated_rights USING btree (id_right);


ALTER TABLE ONLY imc.users_delegated_rights
    ADD CONSTRAINT fk_users_delegated_rights_id_from_owner FOREIGN KEY (id_from_owner) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.users_delegated_rights
    ADD CONSTRAINT fk_users_delegated_rights_id_user FOREIGN KEY (id_user) REFERENCES imc.users(id_user);


ALTER TABLE ONLY imc.users_delegated_rights
    ADD CONSTRAINT fk_users_delegated_rights_id_allowed_act FOREIGN KEY (id_allowed_act) REFERENCES imc.allowed_access_objects_acts(id_allowed_act);

-- ??????
-- ALTER TABLE ONLY imc.users_delegated_rights
--     ADD CONSTRAINT fk_users_delegated_rights_id_allowed_acc_obj FOREIGN KEY (id_allowed_acc_obj) REFERENCES imc.(id_allowed_acc_obj);



--
-- Name: TABLE users_delegated_rights; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.users_delegated_rights IS 'Права, делегированные пользователям владельцами объектов доступа. Номер схемы: 64';


--
-- Name: COLUMN users_delegated_rights.id_right; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users_delegated_rights.id_right IS 'Идентификатор права пользователя';

--
-- Name: COLUMN users_delegated_rights.id_from_owner; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users_delegated_rights.id_from_owner IS 'Кем (каким владельцем объекта доступа) делегировано право пользователю';

--
-- Name: COLUMN users_delegated_rights.id_user; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users_delegated_rights.id_user IS 'Идентификатор пользователя, которому делегировано право';

--
-- Name: COLUMN users_delegated_rights.id_allowed_act; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users_delegated_rights.id_allowed_act IS 'Идентификатор действия, которое делегировано пользователю в качестве права';

--
-- Name: COLUMN users_delegated_rights.id_allowed_acc_obj; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users_delegated_rights.id_allowed_acc_obj IS 'Идентификатор объекта доступа, право на действие с которым делегировано пользователю';

--
-- Name: COLUMN users_delegated_rights.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.users_delegated_rights.order_in_list IS 'Порядковый номер (номер позиции) права пользователя в списке прав одного пользователя внутри одного делегированного действия (нужен для организации web-интерфейсов). Значение: от 1 до N, по триггеру INSERT';








-- Таблица : Виды прав на действия с Wed-интерфейсами
--
-- Name: web_rights_kinds; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 65 (номер схемы: 65)
--

CREATE TABLE imc.web_rights_kinds (
    id_web_right_kind uuid UNIQUE NOT NULL,

    name text NOT NULL,
    note text DEFAULT NULL,

    order_in_list integer UNIQUE NOT NULL

);


ALTER TABLE imc.web_rights_kinds OWNER TO postgres;

--
-- Name: web_rights_kinds pk_web_rights_kinds; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.web_rights_kinds
    ADD CONSTRAINT pk_web_rights_kinds PRIMARY KEY (id_web_right_kind);

--
-- Name: web_rights_kinds_id_web_right_kind_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_web_rights_kinds_id_web_right_kind_key ON imc.web_rights_kinds USING btree (id_web_right_kind);



--
-- Name: TABLE web_rights_kinds; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.web_rights_kinds IS 'Виды прав на действия с Wed-интерфейсами. Номер схемы: 65';


--
-- Name: COLUMN web_rights_kinds.id_web_right_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.web_rights_kinds.id_web_right_kind IS 'Идентификатор вида права';


--
-- Name: COLUMN web_rights_kinds.name; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.web_rights_kinds.name IS 'Название вида права';

--
-- Name: COLUMN web_rights_kinds.note; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.web_rights_kinds.note IS 'Заметка о виде права';

--
-- Name: COLUMN web_rights_kinds.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.web_rights_kinds.order_in_list IS 'Порядковый номер (номер позиции) вида права в списке видов прав (нужен для организации web-интерфейсов). Значение: от 1 до N, по триггеру INSERT';




INSERT INTO imc.web_rights_kinds (id_web_right_kind, name, note, order_in_list) 
VALUES ('835e2070-6949-4248-9f44-b1982963daaa', 'Использовать глобальный поиск', NULL, 1);

INSERT INTO imc.web_rights_kinds (id_web_right_kind, name, note, order_in_list) 
VALUES ('af9ea1df-45c4-4624-a5d5-0321c057e97f', 'Перейти по ссылке к web-интерфейсам администрирования доступа (пользователи, роли, права)', NULL, 2);





-- Таблица : Права ролей на действия с Wed-интерфейсами
--
-- Name: roles_web_rights; Type: TABLE; Schema: imc; Owner: postgres
--
--
--
-- стр.: 66 (номер схемы: 66)
--

CREATE TABLE imc.roles_web_rights (
    id_web_right uuid UNIQUE NOT NULL,

    id_role uuid NOT NULL,
    id_web_right_kind uuid NOT NULL,

    order_in_list integer NOT NULL,


    CONSTRAINT roles_web_rights_1 UNIQUE (id_role, id_web_right_kind),
    CONSTRAINT roles_web_rights_2 UNIQUE (id_role, order_in_list)

);


ALTER TABLE imc.roles_web_rights OWNER TO postgres;

--
-- Name: roles_web_rights pk_roles_web_rights; Type: CONSTRAINT; Schema: imc; Owner: postgres
--

ALTER TABLE ONLY imc.roles_web_rights
    ADD CONSTRAINT pk_roles_web_rights PRIMARY KEY (id_web_right);

--
-- Name: roles_web_rights_id_web_right_key; Type: INDEX; Schema: imc; Owner: postgres
--

CREATE UNIQUE INDEX imc_roles_web_rights_id_web_right_key ON imc.roles_web_rights USING btree (id_web_right);


ALTER TABLE ONLY imc.roles_web_rights
    ADD CONSTRAINT fk_roles_web_rights_id_role FOREIGN KEY (id_role) REFERENCES imc.roles(id_role);


ALTER TABLE ONLY imc.roles_web_rights
    ADD CONSTRAINT fk_roles_web_rights_id_web_right_kind FOREIGN KEY (id_web_right_kind) REFERENCES imc.web_rights_kinds(id_web_right_kind);



--
-- Name: TABLE roles_web_rights; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON TABLE imc.roles_web_rights IS 'Права ролей на действия с Wed-интерфейсами. Номер схемы: 66';


--
-- Name: COLUMN roles_web_rights.id_web_right; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles_web_rights.id_web_right IS 'Идентификатор права роли';

--
-- Name: COLUMN roles_web_rights.id_role; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles_web_rights.id_role IS 'Идентификатор роли, которой предоставлено право';

--
-- Name: COLUMN roles_web_rights.id_web_right_kind; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles_web_rights.id_web_right_kind IS 'Идентификатор вида права, которое предоставлено роли';

--
-- Name: COLUMN roles_web_rights.order_in_list; Type: COMMENT; Schema: imc; Owner: postgres
--

COMMENT ON COLUMN imc.roles_web_rights.order_in_list IS 'Порядковый номер (номер позиции) права роли в списке прав одной роли (нужен для организации web-интерфейсов). Значение: от 1 до N, по триггеру INSERT';









COMMIT;
