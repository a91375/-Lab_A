-- 建立新回合（不變）
drop proc if exists StartGuessNumberGame
go
create procedure StartGuessNumberGame
    @player_uid nvarchar(20)
as
begin
    set nocount on;

    -- 產生1~100的隨機數字
    declare @computer_number int
    set @computer_number = cast(rand() * 100 + 1 as int)

    -- 建立新回合
    insert into GuessNumberGame (player_uid, computer_number)
    values (@player_uid, @computer_number)

    -- 回傳新回合編號
    select scope_identity() as round_id
end
go

-- 遊戲猜測介面
drop proc if exists PlayGuessNumberGame
go
create procedure PlayGuessNumberGame
    @round_id int,
    @player_uid nvarchar(20),
    @guess_number int
as
begin
    set nocount on;

    -- 取得本回合電腦數字與狀態
    declare @computer_number int, @is_finished bit, @round_player_uid nvarchar(20)
    select @computer_number = computer_number, @is_finished = is_finished, @round_player_uid = player_uid
    from GuessNumberGame
    where round_id = @round_id

    -- 檢查玩家帳號是否正確
    if @player_uid <> @round_player_uid
    begin
        select N'玩家帳號錯誤' as message
        return
    end

    -- 若回合已結束則不允許再猜
    if @is_finished = 1
    begin
        select N'本回合已結束，請重新開始新回合' as message
        return
    end

    -- 判斷猜測結果
    declare @result nvarchar(10)
    if @guess_number = @computer_number
        set @result = N'猜對了'
    else if @guess_number > @computer_number
        set @result = N'太大'
    else
        set @result = N'太小'

    -- 寫入猜測紀錄
    insert into GuessNumberGameDetail (round_id, guess_number, result)
    values (@round_id, @guess_number, @result)

    -- 若猜對則更新回合結束
    if @result = N'猜對了'
    begin
        update GuessNumberGame
        set is_finished = 1,
            end_time = getdate()
        where round_id = @round_id
    end

    -- 回傳本次猜測結果
    select @result as result
end