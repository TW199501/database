
-- =============================================
-- �W�١Gsp_insert_customer
-- �\��G���U�|���]customer + customer_profile�^�A�䴩�Ҧ������
-- �γ~�G���ѫe�ݵ��U���� / API �����ե�
--�d��
--EXEC dbo.sp_insert_customer
--    @email = N'testuser@example.com',
--    @password = N'Abcd1234!',
--    @full_name = N'�p���K�J',
--    @mobile = N'0937277473',
--    @zipcode = N'106',
--    @district = N'�x�_���j�w��',
--    @address = N'�M���F���G�q101��',
--    @id_number = N'A123456789',
--    @gender = N'M',
--    @birthday = '1990-08-01';
-- =============================================
CREATE OR ALTER PROCEDURE dbo.sp_insert_customer
    @email NVARCHAR(100),         -- �n�J�b���]����^
    @password NVARCHAR(255),      -- �K�X�]����^
    @full_name NVARCHAR(50),      -- ����m�W�]����^
    @mobile NVARCHAR(50),         -- ������X�]����^
    @zipcode NVARCHAR(10) = NULL, -- �l���ϸ��]�i��^
    @district NVARCHAR(50) = NULL,-- �����m��]�i��^
    @address NVARCHAR(200) = NULL,-- �ԲӦa�}�]�i��^
    @id_number NVARCHAR(20) = NULL, -- �����Ҧr���]�i��^
    @gender CHAR(1) = NULL,       -- �ʧO M/F�]�i��^
    @birthday DATE = NULL         -- �X�ͤ���]�i��^
AS
BEGIN
    SET NOCOUNT ON;

    -- �ˬd�b���O�_����
    IF EXISTS (SELECT 1 FROM dbo.customer WHERE email = @email)
    BEGIN
        RAISERROR('���b���w�s�b�A�ШϥΨ�L�b��', 16, 1);
        RETURN;
    END

    -- �إ� GUID �D��
    DECLARE @customer_id UNIQUEIDENTIFIER = NEWID();
    DECLARE @f_tenant_id VARCHAR(50) = '0'; -- �t�ιw�]

    -- �s�W customer�]�D��^
    INSERT INTO dbo.customer (
        customer_id, email, password, full_name, is_locked, created_at,
        f_tenant_id
    )
    VALUES (
        @customer_id, @email, @password, @full_name, 0, GETDATE(),
        @f_tenant_id
    );

    -- �s�W customer_profile�]�X�R��ơ^
    INSERT INTO dbo.customer_profile (
        customer_id, full_name, mobile, zipcode, district, address,
        id_number, gender, birthday, f_tenant_id
    )
    VALUES (
        @customer_id, @full_name, @mobile, @zipcode, @district, @address,
        @id_number, @gender, @birthday, @f_tenant_id
    );
END;
GO
