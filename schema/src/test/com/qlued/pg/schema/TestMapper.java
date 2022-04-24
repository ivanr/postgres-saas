package com.qlued.pg.schema;

import com.qlued.pg.model.Tenant;
import com.qlued.pg.model.TenantNote;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

public interface TestMapper {

    @Update("SELECT rls_set_tenant_id(#{tenantId}, #{keyId}, #{key})")
    void setTenantId(@Param("tenantId") String tenantId, @Param("keyId") String keyId, @Param("key") String key);

    @Insert("INSERT INTO tenants (tenant_id, name) VALUES (#{tenantId}::UUID, #{name})")
    void insertTenant(Tenant tenant);

    @Insert("INSERT INTO tenant_notes (tenant_id, note) VALUES (#{tenantId}::UUID, #{note})")
    void insertNote(TenantNote tenantNote);
}
