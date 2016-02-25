class OwnershipsController < ApplicationController
  before_action :logged_in_user

  def create
    if params[:asin] #もしもアマゾンのデータだったら
      @item = Item.find_or_initialize_by(asin: params[:asin]) #Itemテーブルを取得して無ければ新規作成
    else
      @item = Item.find(params[:item_id])
      @item.save
    end

    # @itemがitemsテーブルに存在しない場合はAmazonのデータを登録する。
    if @item.new_record?
      begin
        # TODO 商品情報の取得 Amazon::Ecs.item_lookupを用いてください
        response = Amazon::Ecs.item_lookup(params[:asin] ,  #アマゾンのデータ取得して
                                  :response_group => 'Medium' , 
                                  :country => 'jp')
      rescue Amazon::RequestError => e
        return render :js => "alert('#{e.message}')"
      end

      amazon_item       = response.items.first
      @item.title        = amazon_item.get('ItemAttributes/Title')
      @item.small_image  = amazon_item.get("SmallImage/URL")
      @item.medium_image = amazon_item.get("MediumImage/URL")
      @item.large_image  = amazon_item.get("LargeImage/URL")
      @item.detail_page_url = amazon_item.get("DetailPageURL")
      @item.raw_info        = amazon_item.get_hash
      @item.save! #Itemの中に情報を保存
    end
    
    # typeがhaveの場合、ownaershipテーブルに情報を保存したい type:haveとして保存、
    if params[:type] == 'Have' #haveの場合は
      current_user.have(@item) #current_userにhaveメソッドを実行する
    # wantしている商品
    else
      current_user.want(@item)
    end
      
  end

    # TODO ユーザにwant or haveを設定する
    # params[:type]の値ににHaveボタンが押された時には「Have」,
    # Wantボタンがされた時には「Want」が設定されています。
    
  def destroy
    @item = Item.find(params[:item_id])
    if params[:type] == 'Have' #haveの場合は
      current_user.unhave(@item) #current_userにhaveメソッドを実行する
    # wantしている商品
    else
      current_user.unwant(@item)
    end
    
    # TODO 紐付けの解除。 
    # params[:type]の値にHave itボタンが押された時には「Have」,
    # Want itボタンが押された時には「Want」が設定されています。
   
    #@item = current_user.haves.Item.find(params[:item_id]).unhave
    #current_user.unhave(@item)
    

  end
end