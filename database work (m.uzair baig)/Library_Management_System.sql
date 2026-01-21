--CREATE DATABASE Library;
USE Library;

CREATE TABLE Books (
    ISBN VARCHAR(25) PRIMARY KEY,
    Book_title VARCHAR(80),
    Category VARCHAR(30),
    Rental_Price DECIMAL(10,2),
    Status VARCHAR(3) CHECK (Status IN ('Yes', 'No')),
    Author VARCHAR(30),
    Publisher VARCHAR(30)
);

CREATE TABLE Branch (
    Branch_no VARCHAR(10) PRIMARY KEY,
    Manager_id VARCHAR(10),
    Branch_address VARCHAR(100),
    Contact_no VARCHAR(15)
);

CREATE TABLE Customer (
    Customer_Id VARCHAR(10) PRIMARY KEY,
    Customer_name VARCHAR(30),
    Customer_address VARCHAR(30),
    Reg_date DATE
);

CREATE TABLE Employee (
    Emp_id VARCHAR(10) PRIMARY KEY,
    Emp_name VARCHAR(50),
    Position VARCHAR(30),
    Salary DECIMAL(10,2),
    Branch_no VARCHAR(10),
    FOREIGN KEY (Branch_no) REFERENCES Branch(Branch_no)
);

CREATE TABLE IssueStatus (
    Issue_Id INT PRIMARY KEY IDENTITY(1,1),
    Isbn_book VARCHAR(25),
    Issued_cust VARCHAR(10),
    Issue_date DATE DEFAULT GETDATE(),
    Return_date DATE NULL ,
    Status VARCHAR(10) CHECK (Status IN ('Issued', 'Returned')),
    FOREIGN KEY (Isbn_book) REFERENCES Books(ISBN) ON DELETE CASCADE,
    FOREIGN KEY (Issued_cust) REFERENCES Customer(Customer_Id) ON DELETE CASCADE
);



CREATE PROCEDURE ManageBooks
    @Action VARCHAR(10),         -- 'INSERT', 'UPDATE', 'DELETE'
    @ISBN VARCHAR(25),
    @Book_title VARCHAR(100) = NULL,
    @Category VARCHAR(50) = NULL,
    @Rental_Price DECIMAL(10,2) = NULL,
    @Status VARCHAR(3) = NULL,
    @Author VARCHAR(50) = NULL,
    @Publisher VARCHAR(50) = NULL
AS
BEGIN
    IF @Action = 'INSERT'
    BEGIN
        INSERT INTO Books (ISBN, Book_title, Category, Rental_Price, Status, Author, Publisher)
        VALUES (@ISBN, @Book_title, @Category, @Rental_Price, @Status, @Author, @Publisher);
    END
    ELSE IF @Action = 'UPDATE'
    BEGIN
        UPDATE Books
        SET Book_title = @Book_title,
            Category = @Category,
            Rental_Price = @Rental_Price,
            Status = @Status,
            Author = @Author,
            Publisher = @Publisher
        WHERE ISBN = @ISBN;
    END
    ELSE IF @Action = 'DELETE'
    BEGIN
        DELETE FROM Books WHERE ISBN = @ISBN;
    END
END;

CREATE PROCEDURE ManageBranch
    @Action VARCHAR(10),             -- INSERT, UPDATE, DELETE
    @Branch_no VARCHAR(10),
    @Manager_id VARCHAR(10) = NULL,
    @Branch_address VARCHAR(100) = NULL,
    @Contact_no VARCHAR(15) = NULL
AS
BEGIN
    IF @Action = 'INSERT'
    BEGIN
        INSERT INTO Branch (Branch_no, Manager_id, Branch_address, Contact_no)
        VALUES (@Branch_no, @Manager_id, @Branch_address, @Contact_no);
    END
    ELSE IF @Action = 'UPDATE'
    BEGIN
        UPDATE Branch
        SET Manager_id = @Manager_id,
            Branch_address = @Branch_address,
            Contact_no = @Contact_no
        WHERE Branch_no = @Branch_no;
    END
    ELSE IF @Action = 'DELETE'
    BEGIN
        DELETE FROM Branch WHERE Branch_no = @Branch_no;
    END
END;


CREATE PROCEDURE ManageEmployee
    @Action VARCHAR(10),         -- INSERT, UPDATE, DELETE
    @Emp_id VARCHAR(10),
    @Emp_name VARCHAR(50) = NULL,
    @Position VARCHAR(30) = NULL,
    @Salary DECIMAL(10,2) = NULL,
    @Branch_no VARCHAR(10) = NULL
AS
BEGIN
    IF @Action = 'INSERT'
    BEGIN
        INSERT INTO Employee (Emp_id, Emp_name, Position, Salary, Branch_no)
        VALUES (@Emp_id, @Emp_name, @Position, @Salary, @Branch_no);
    END
    ELSE IF @Action = 'UPDATE'
    BEGIN
        UPDATE Employee
        SET Emp_name = @Emp_name,
            Position = @Position,
            Salary = @Salary,
            Branch_no = @Branch_no
        WHERE Emp_id = @Emp_id;
    END
    ELSE IF @Action = 'DELETE'
    BEGIN
        DELETE FROM Employee WHERE Emp_id = @Emp_id;
    END
END;


CREATE PROCEDURE ManageCustomer
    @Action VARCHAR(10),              -- INSERT, UPDATE, DELETE
    @Customer_Id VARCHAR(10),
    @Customer_name VARCHAR(50) = NULL,
    @Customer_address VARCHAR(100) = NULL,
    @Reg_date DATE = NULL
AS
BEGIN
    IF @Action = 'INSERT'
    BEGIN
        INSERT INTO Customer (Customer_Id, Customer_name, Customer_address, Reg_date)
        VALUES (@Customer_Id, @Customer_name, @Customer_address, @Reg_date);
    END
    ELSE IF @Action = 'UPDATE'
    BEGIN
        UPDATE Customer
        SET Customer_name = @Customer_name,
            Customer_address = @Customer_address,
            Reg_date = @Reg_date
        WHERE Customer_Id = @Customer_Id;
    END
    ELSE IF @Action = 'DELETE'
    BEGIN
        DELETE FROM Customer WHERE Customer_Id = @Customer_Id;
    END
END;

CREATE PROCEDURE IssueBook
    @ISBN VARCHAR(25),
    @Customer_Id VARCHAR(10)
AS
BEGIN
    DECLARE @BookStatus VARCHAR(3);

    -- Check if book is available
    SELECT @BookStatus = Status FROM Books WHERE ISBN = @ISBN;

    IF @BookStatus = 'Yes'
    BEGIN
        -- Insert into IssueStatus
        INSERT INTO IssueStatus (Isbn_book, Issued_cust, Status)
        VALUES (@ISBN, @Customer_Id, 'Issued');

        -- Mark book as not available
        UPDATE Books
        SET Status = 'No'
        WHERE ISBN = @ISBN;

        PRINT 'Book issued successfully.';
    END
    ELSE
    BEGIN
        PRINT 'Sorry, no stock available.';
    END
END;


CREATE PROCEDURE ReturnBook
    @Customer_Id VARCHAR(10),
    @ISBN VARCHAR(25)
AS
BEGIN
    DECLARE @Issue_Id INT;

    -- Get the latest Issue_Id for this customer and book that is still marked as 'Issued'
    SELECT TOP 1 @Issue_Id = Issue_Id
    FROM IssueStatus
    WHERE Isbn_book = @ISBN
      AND Issued_cust = @Customer_Id
      AND Status = 'Issued'
    ORDER BY Issue_date DESC;

    IF @Issue_Id IS NOT NULL
    BEGIN
        -- Update status and return date in IssueStatus
        UPDATE IssueStatus
        SET Status = 'Returned',
            Return_date = GETDATE()
        WHERE Issue_Id = @Issue_Id;

        -- Mark the book as available in Books table
        UPDATE Books
        SET Status = 'Yes'
        WHERE ISBN = @ISBN;

        PRINT 'Book returned successfully.';
    END
    ELSE
    BEGIN
        PRINT 'No active issue record found for this customer and book.';
    END
END;

--TRIGGERS 


-- Book Log Table
CREATE TABLE BookLog (
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    ISBN VARCHAR(25),
    ActionType VARCHAR(10),
    ActionTime DATETIME DEFAULT GETDATE()
);
-- Insert Trigger for Books
CREATE TRIGGER trg_BookInsert
ON Books
AFTER INSERT
AS
BEGIN
    INSERT INTO BookLog (ISBN, ActionType)
    SELECT ISBN, 'INSERT' FROM inserted;
END;
-- Delete Trigger for Books
CREATE TRIGGER trg_BookDelete
ON Books
AFTER DELETE
AS
BEGIN
    INSERT INTO BookLog (ISBN, ActionType)
    SELECT ISBN, 'DELETE' FROM deleted;
END;
-- Update Trigger for Books
CREATE TRIGGER trg_BookUpdate
ON Books
AFTER UPDATE
AS
BEGIN
    INSERT INTO BookLog (ISBN, ActionType)
    SELECT ISBN, 'UPDATE' FROM inserted;
END;


-- Customer Log Table
CREATE TABLE CustomerLog (
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    Customer_Id VARCHAR(10),
    ActionType VARCHAR(10),
    ActionTime DATETIME DEFAULT GETDATE()
);
-- Insert Trigger
CREATE TRIGGER trg_CustomerInsert
ON Customer
AFTER INSERT
AS
BEGIN
    INSERT INTO CustomerLog (Customer_Id, ActionType)
    SELECT Customer_Id, 'INSERT' FROM inserted;
END;
-- Delete Trigger
CREATE TRIGGER trg_CustomerDelete
ON Customer
AFTER DELETE
AS
BEGIN
    INSERT INTO CustomerLog (Customer_Id, ActionType)
    SELECT Customer_Id, 'DELETE' FROM deleted;
END;


-- Employee Log Table
CREATE TABLE EmployeeLog (
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    Emp_Id VARCHAR(10),
    ActionType VARCHAR(10),
    ActionTime DATETIME DEFAULT GETDATE()
);
--Employee Insert Trigger
CREATE TRIGGER trg_EmployeeInsert
ON Employee
AFTER INSERT
AS
BEGIN
    INSERT INTO EmployeeLog (Emp_Id, ActionType)
    SELECT Emp_Id, 'INSERT' FROM inserted;
END;
--Employee Delete Trigger
CREATE TRIGGER trg_EmployeeDelete
ON Employee
AFTER DELETE
AS
BEGIN
    INSERT INTO EmployeeLog (Emp_Id, ActionType)
    SELECT Emp_Id, 'DELETE' FROM deleted;
END;


--INSERT INTO BOOKS
EXEC ManageBooks 'INSERT', '978-0-09-957807-9', 'A Game of Thrones', 'Fantasy', 7.5, 'Yes', 'George R.R. Martin', 'Bantam';
EXEC ManageBooks 'INSERT', '978-0-14-044930-3', 'The Histories', 'History', 5.5, 'Yes', 'Herodotus', 'Penguin Classics';
EXEC ManageBooks 'INSERT', '978-0-14-118776-1', 'One Hundred Years of Solitude', 'Literary Fiction', 6.5, 'Yes', 'Gabriel Garcia Marquez', 'Penguin Books';
EXEC ManageBooks 'INSERT', '978-0-141-44171-6', 'Jane Eyre', 'Classic', 4.0, 'Yes', 'Charlotte Bronte', 'Penguin Classics';
EXEC ManageBooks 'INSERT', '978-0-19-280551-1', 'The Guns of August', 'History', 7.0, 'Yes', 'Barbara W. Tuchman', 'Oxford University Press';
EXEC ManageBooks 'INSERT', '978-0-307-37840-1', 'The Alchemist', 'Fiction', 2.5, 'Yes', 'Paulo Coelho', 'HarperOne';
EXEC ManageBooks 'INSERT', '978-0-307-58837-1', 'Sapiens: A Brief History of Humankind', 'History', 8.0, 'Yes', 'Yuval Noah Harari', 'Harper Perennial';
EXEC ManageBooks 'INSERT', '978-0-330-25864-8', 'Animal Farm', 'Classic', 5.5, 'Yes', 'George Orwell', 'Penguin Books';
EXEC ManageBooks 'INSERT', '978-0-375-41398-8', 'The Diary of a Young Girl', 'History', 6.5, 'Yes', 'Anne Frank', 'Bantam';
EXEC ManageBooks 'INSERT', '978-0-393-05081-8', 'A People''s History of the United States', 'History', 9.0, 'Yes', 'Howard Zinn', 'Harper Perennial';
EXEC ManageBooks 'INSERT', '978-0-393-91257-8', 'Guns, Germs, and Steel: The Fates of Human Societies', 'History', 7.0, 'Yes', 'Jared Diamond', 'W. W. Norton & Company';
EXEC ManageBooks 'INSERT', '978-0-525-47535-5', 'The Great Gatsby', 'Classic', 8.0, 'Yes', 'F. Scott Fitzgerald', 'Scribner';
EXEC ManageBooks 'INSERT', '978-0-553-29698-2', 'The Catcher in the Rye', 'Classic', 7.0, 'Yes', 'J.D. Salinger', 'Little, Brown and Company';
EXEC ManageBooks 'INSERT', '978-0-679-76489-8', 'Harry Potter and the Sorcerer''s Stone', 'Fantasy', 7.0, 'Yes', 'J.K. Rowling', 'Scholastic';
EXEC ManageBooks 'INSERT', '978-0-7432-4722-4', 'The Da Vinci Code', 'Mystery', 8.0, 'Yes', 'Dan Brown', 'Doubleday';
EXEC ManageBooks 'INSERT', '978-0-7432-7357-1', '1491: New Revelations of the Americas Before Columbus', 'History', 6.5, 'Yes', 'Charles C. Mann', 'Vintage Books';

select * from BookLog;
select * from Books;


--INSERT INTO CUSTOMERS
EXEC ManageCustomer 'INSERT', 'C101', 'Zaeem', '123 Main St', '2021-05-15';
EXEC ManageCustomer 'INSERT', 'C102', 'Uzair', '456 Elm St', '2021-06-20';
EXEC ManageCustomer 'INSERT', 'C103', 'Ghufran', '789 Oak St', '2021-07-10';
EXEC ManageCustomer 'INSERT', 'C104', 'Ahsan', '567 Pine St', '2021-08-05';
EXEC ManageCustomer 'INSERT', 'C105', 'Waleed', '890 Maple St', '2021-09-25';
EXEC ManageCustomer 'INSERT', 'C106', 'Shayan', '234 Cedar St', '2021-10-15';

select * from Customer;
select * from CustomerLog;


--INSERT INTO BRANCH
EXEC ManageBranch 'INSERT', 'B001', 'M101', '123 Karachi', 919100000000;
EXEC ManageBranch 'INSERT', 'B002', 'M102', '456 Islamabad', 919100000000;
EXEC ManageBranch 'INSERT', 'B003', 'M103', '789 Lahore', 919100000000;
EXEC ManageBranch 'INSERT', 'B004', 'M104', '567 Peshawer', 919100000000;
EXEC ManageBranch 'INSERT', 'B005', 'M105', '890 Queta', 919100000000;

select * from Branch;


--INSERT INTO EMPLOYEE
EXEC ManageEmployee 'INSERT', 'M101', 'HAMZA', 'Manager', 60000, 'B001';
EXEC ManageEmployee 'INSERT', 'M102', 'ALI', 'Manager', 45000, 'B002';
EXEC ManageEmployee 'INSERT', 'M103', 'AHMED', 'Manager', 55000, 'B003';
EXEC ManageEmployee 'INSERT', 'M104', 'RAFAY', 'Manager', 40000, 'B004';
EXEC ManageEmployee 'INSERT', 'M105', 'TALHA', 'Manager', 42000, 'B005';
EXEC ManageEmployee 'INSERT', 'E101', 'HAMMAD', 'Employees', 43000, 'B001';
EXEC ManageEmployee 'INSERT', 'E102', 'MAAZ', 'Employees', 62000, 'B002';
EXEC ManageEmployee 'INSERT', 'E103', 'HASSAN', 'Employees', 46000, 'B003';
EXEC ManageEmployee 'INSERT', 'E104', 'SAAD', 'Employees', 57000, 'B004';
EXEC ManageEmployee 'INSERT', 'E105', 'REYAN', 'Employees', 41000, 'B005';

select *from Employee;
select * from EmployeeLog;

-- Issue Book 
EXEC IssueBook '978-0-553-29698-2','C101';
EXEC IssueBook '978-0-7432-4722-4','C102';
EXEC IssueBook '978-0-7432-7357-1','C103';
EXEC IssueBook'978-0-307-58837-1','C104';
EXEC IssueBook '978-0-375-41398-8','C105';

select * from IssueStatus;


update Books set Status='yes' where ISBN='978-0-375-41398-8';


--Return Book
exec ReturnBook 'C101','978-0-553-29698-2';
exec ReturnBook 'C102','978-0-7432-4722-4';
exec ReturnBook 'C103','978-0-7432-7357-1';
exec ReturnBook 'C104','978-0-307-58837-1';
exec ReturnBook 'C105','978-0-375-41398-8';

select * from Customer c  join IssueStatus i on c.Customer_Id=i.Issued_cust where i.Status='Issued';