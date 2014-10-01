<link rel="stylesheet" type="text/css" href="[+site_url+]assets/plugins/simplegallery/js/easy-ui/themes/bootstrap/easyui.css">
<link rel="stylesheet" type="text/css" href="[+site_url+]assets/plugins/simplegallery/js/easy-ui/themes/icon.css">
<link rel="stylesheet" type="text/css" href="[+site_url+]assets/plugins/simplegallery/css/style.css">
<style type="text/css">
.sg_image {
	width:[+w+]px;
}
.sg_image img {
	width:[+w+]px;
	height:[+h+]px;
}
.sg_image .del {
	background: url([+manager_url+]media/style/[+theme+]/images/icons/delete.png) 0 0 no-repeat;
}
.btn-deleteAll {
	background: url([+manager_url+]media/style/[+theme+]/images/icons/trash.png) -2px center no-repeat;
}
</style>
<script type="text/javascript">
var rid = [+id+],
    sgLoaded = false,
    sgTotal = [+total+],
    sgSort = null,
    sgFileId = 0,
    sgLastChecked = null,
    sgBeforeDragState = null;
(function($){

	$.fn.pagination.defaults.pageList = [50,100,150,200];
	var sgHelper = {
		init: function() {
			$('#SimpleGallery').append('<div class="js-fileapi-wrapper"><div class="btn"><div class="btn-text"><img src="[+manager_url+]media/style/[+theme+]/images/icons/folder_page_add.png">'+_sgLang['upload']+'</div><input id="sg_files" name="sg_files" class="btn-input" type="file" multiple /></div>[+refreshBtn+]<div id="sg_pages"></div><div id="sg_images"></div><div style="clear:both;"></div></div>');
			$('#sg_refresh').click(function(){
		    	sgHelper.refresh();
		    });
			$('#SimpleGallery').fileapi({
            	url: '[+site_url+]assets/plugins/simplegallery/ajax.php?mode=upload',
            	autoUpload: true,
            	accept: 'image/*',
            	multiple: true,
            	clearOnSelect: true,
            	data: {
            		'sg_rid': [+id+]
            	},
            	filterFn: function (file, info) {
            		return /jpeg|gif|png$/.test(file.type) 
            	},
            	onBeforeUpload: function(e,uiE) {
	            	var total = uiE.files.length;
	            	var uploadStateForm = $('<div id="sgUploadState"><div id="sgProgress"><span></span><div></div></div><table><thead><tr><th class="sgrow1">'+_sgLang['file']+'</th><th class="sgrow2">'+_sgLang['size']+'</th><th class="sgrow3">'+_sgLang['progress']+'</th></tr></thead></table><div id="sgFilesList"><table><tbody></tbody></table></div><div style="clear:both;padding:10px;float:right;"><div id="sgUploadCancel" class="btn btn-right"><div class="btn-text"><img src="[+manager_url+]media/style/[+theme+]/images/icons/stop.png"><span>'+_sgLang['cancel']+'</span></div></div></div></div>');
	            	$.each(uiE.files,function(i,file){
	            		$('tbody',uploadStateForm).append('<tr id="sgFilesListRow'+(i+1)+'"><td class="sgrow1">'+file.name+'</td><td class="sgrow2">'+sgHelper.bytesToSize(file.size)+'</td><td class="sgrow3 progress"></td></tr>')
	            	});
	            	uploadStateForm.window({
	    				width:450,
	    				modal:true,
	    				title:_sgLang['files_upload'],
	    				doSize:true,
		    			collapsible:false,
		    			minimizable:false,
		    			maximizable:false,
		    			resizable:false,
		    			onOpen: function() {
	            			$('body').css('overflow','hidden');
	            			$('#sgProgress > span').html(_sgLang['uploaded']+' <span>'+sgFileId+'</span> '+_sgLang['from']+' '+total);
	            			$('#sgUploadCancel').click(function(e){
	            				$('#sgUploadState').window('close');
	            			})
		    			},
		    			onClose: function() {
		    				$('#SimpleGallery').fileapi('abort');
		    				$('#sgUploadState').window('destroy',true);
		    				$('.window-shadow,.window-mask').remove();
		    				$('body').css('overflow','auto');
		    			}
		    		});
            	},
            	onProgress: function (e, uiE){
    				var part = uiE.loaded / uiE.total;
    				$('#sgProgress > div').css('width',100*part+'%');
				},
				onFilePrepare: function (e,uiE) {
					sgFileId++;
				},
				onFileProgress: function (e,uiE) {
					var part = uiE.loaded / uiE.total;
					$('.progress','#sgFilesListRow'+sgFileId).text(Math.floor(100*part)+'%');
				},
            	onFileComplete: function(e,uiE) {
    				$('#sgProgress > span > span').text(sgFileId);
            	},
            	onComplete: function(e,uiE) {
            		sgFileId = 0;
            		var btn = $('#sg_files');
            		btn.replaceWith(btn.val('').clone(true));
            		e.widget.files = [];
            		e.widget.uploaded = [];
            		$('#sg_pages').pagination('select');
            		$('#sgUploadCancel span').text(_sgLang['close']);
            	},
            	elements: {
          			dnd: {
	        			el: '.js-fileapi-wrapper',
			        	hover: 'dnd_hover'
      				}
            	}
        	});
        	$('#sg_pages').pagination({
			    total:[+total+],
			    pageSize:10,
	    		buttons: [{
					iconCls:'btn-deleteAll',
					handler:function(){sgHelper.deleteAll();}
				}],
			    onSelectPage:function(pageNumber, pageSize){
					$(this).pagination('loading');
						$.post("[+url+]", { rows: pageSize, page: pageNumber, sg_rid: [+id+] }, function(data) {
							var result = $.parseJSON(data);
							$('#sg_pages').pagination('refresh',{total: result.total});
							sgHelper.renderImages(result.rows);
						});
					$(this).pagination('loaded');
				}
			});
			$('.btn-deleteAll').parent().parent().hide();
		},
		renderImages: function(rows) {
			var len = rows.length;
			var placeholder = $('#sg_images');
			placeholder.html('');
			for (i = 0; i < len; i++) {
 				var image = $('<div class="sg_image"><a href="javascript:void(0)" class="del"></a><img title="'+this.escape(this.stripText(rows[i].sg_description,100))+'" src="[+thumb_prefix+]'+rows[i].sg_image+'"><div class="name'+(parseInt(rows[i].sg_isactive) ? '' : ' notactive')+'">'+rows[i].sg_title+'</div></div>');
 				rows[i].sg_properties = $.parseJSON(rows[i].sg_properties);
 				image.data('properties',rows[i]);
 				placeholder.append(image);
			}
			this.initImages();
		},
		initImages: function() {
			var _this = this;
			$(document).keydown(function(e) {
        		return !_this.selectAll(e);
    		});
    		$('.del','.sg_image').click(function(e) {
    			_this.delete($(this).parent());
    		});
			$('.sg_image').unbind();
    		$('.sg_image').click(function(e) {
        		_this.unselect();
        		_this.select($(this), e);
    		});
    		$('.sg_image').dblclick(function() {
		        _this.unselect();
		        _this.edit($(this));
		    });
		    $('body').attr('ondragstart','');
		    if (sgSort !== null) sgSort.destroy();
		    sgSort = new Sortable(sg_images,{
		    	draggable: '.sg_image',
		    	onStart: function (e) {
		    		sgBeforeDragState = {
		    			prev: e.item.previousSibling != null ? $(e.item.previousSibling).data('properties').sg_index : -1,
		    			next: e.item.nextSibling != null ? $(e.item.nextSibling).data('properties').sg_index : -1
		    		};
		    	},
		    	onEnd: function (e) {
					var sgAfterDragState = {
						prev: e.item.previousSibling != null ? $(e.item.previousSibling).data('properties').sg_index : -1,
		    			next: e.item.nextSibling != null ? $(e.item.nextSibling).data('properties').sg_index : -1
					}
					if (sgAfterDragState.prev == sgBeforeDragState.prev && sgAfterDragState.next == sgBeforeDragState.next) return;
					var source = $(e.item).data('properties');
					sourceIndex = parseInt(source.sg_index); 
					sourceId = source.sg_id;
					var target = e.item.nextSibling == null ? $(e.item.previousSibling).data('properties') : $(e.item.nextSibling).data('properties');
					targetIndex = parseInt(target.sg_index);
					if (targetIndex < sourceIndex && sgAfterDragState.next != -1) targetIndex++;

					if (sourceIndex < targetIndex) {
						var tempIndex = targetIndex,
							item = e.item;
						while(tempIndex >= sourceIndex) {
							$(item).data('properties').sg_index = tempIndex--;
							item = item.nextSibling == null ? item : item.nextSibling;
						}
					} else {
						var tempIndex = targetIndex,
							item = e.item;
						while(tempIndex <= sourceIndex) {
							$(item).data('properties').sg_index = tempIndex++;
							item = item.previousSibling == null ? item : item.previousSibling;;
						}
					}
					$.post(
						"[+url+]?mode=reorder", {
							sg_rid: [+id+], 
							sourceId: sourceId, 
							sourceIndex: sourceIndex, 
							targetIndex: targetIndex 
						},
						function(data) {
							data = $.parseJSON(data);
							if(!data.success) {
								$('#sg_pages').pagination('select');
							} 
						}
					);
		    	}
		    });
		},
		unselect: function() {
		    if (document.selection && document.selection.empty)
        	document.selection.empty() ;
    		else if (window.getSelection) {
        		var sel = window.getSelection();
        		if (sel && sel.removeAllRanges)
        		sel.removeAllRanges();
    		}
		},
		select: function(image,e) {
			if(!sgLastChecked)
                    sgLastChecked = image;
		    if (e.ctrlKey || e.metaKey) {
		        if (image.hasClass('selected'))
		            image.removeClass('selected');
		        else
		            image.addClass('selected');
		    } else if (e.shiftKey) {
		    	var start = $('.sg_image').index(image);
                var end = $('.sg_image').index(sgLastChecked);
                $('.sg_image').slice(Math.min(start,end), Math.max(start,end)+ 1).addClass('selected');

		    } else {
		        $('.sg_image').removeClass('selected');
		        image.addClass('selected');
		        sgLastChecked=image;
		    }
		    var images = $('.sg_image.selected').get();
		    if(images.length > 1) {
		    	$('.btn-deleteAll').parent().parent().show();
		    } else {
		    	$('.btn-deleteAll').parent().parent().hide();
		    }
		},
		selectAll: function(e) {
		    if ((!e.ctrlKey && !e.metaKey) || ((e.keyCode != 65) && (e.keyCode != 97)))
			        return false;
		    var images = $('.sg_image').get();
		    if (images.length) {
		        $.each(images, function(i, image) {
		            if (!$(image).hasClass('selected'))
		                $(image).addClass('selected');
			        });
		    }
		    $('.btn-deleteAll').parent().parent().show();
		    return true;
		},
		delete: function(image) {
			var id = image.data('properties').sg_id;
			$.messager.confirm(_sgLang['delete'],_sgLang['are_you_sure_to_delete'],function(r){
    			if (r){
        			$.post(
						"[+url+]?mode=remove", 
						{id:id},
						function(data) {
							data = $.parseJSON(data);
							if(data.success) {
								$('#sg_pages').pagination('select');
							} else {
								$.messager.alert(_sgLang['error'],_sgLang['delete_fail']);
							}
						}
					);
    			}
			});
		},
		deleteAll: function() {
			var ids = [];
			var images = $('.sg_image.selected');
		    if (images.length) {
		        $.each(images, function(i, image) {
		        	ids.push($(image).data('properties').sg_id);
			    });
		    }
		    ids = ids.join();
		    $.messager.confirm(_sgLang['delete'],_sgLang['are_you_sure_to_delete_many'],function(r){
    			if (r){
        			$.post(
						"[+url+]?mode=removeAll", 
						{ids:ids},
						function(data) {
							data = $.parseJSON(data);
							if(data.success) {
								$('#sg_pages').pagination('select');
								$('.btn-deleteAll').parent().parent().hide();
							} else {
								$.messager.alert(_sgLang['error'],_sgLang['delete_fail']);
							}
						}
					);
    			}
			});
		},
		edit: function(image) {
			var data = image.data('properties');
			var editForm = $('<div id="sgEdit"><div class="sgRow"><div style="font-size:0;text-align:center;"><img src="[+site_url+]'+data.sg_image+'"></div><div><table><tr><td class="rowTitle">ID</td><td>'+data.sg_id+'</td></tr><tr><td class="rowTitle">'+_sgLang['file']+'</td><td>'+data.sg_image+'</td></tr><tr><td class="rowTitle">'+_sgLang['size']+'</td><td>'+data.sg_properties.width+'x'+data.sg_properties.height+', '+this.bytesToSize(data.sg_properties.size)+'</td></tr><tr><td class="rowTitle">'+_sgLang['createdon']+'</td><td>'+data.sg_createdon+'</td></tr></table></div></div><div class="sgRow"><div><form id="sgForm"><input type="hidden" name="sg_id" value="'+data.sg_id+'"><label>'+_sgLang['title']+'</label><input name="sg_title" maxlength="255" type="text" value="'+this.escape(data.sg_title)+'"><label>'+_sgLang['description']+'</label><textarea name="sg_description">'+this.escape(data.sg_description)+'</textarea><label>'+_sgLang['add']+'</label><input name="sg_add" type="text" value="'+this.escape(data.sg_add)+'"><label>'+_sgLang['show']+'</label><input type="checkbox" name="sg_isactive" value="1" '+ (parseInt(data.sg_isactive) ? 'checked' : '')+'>'+_sgLang['yes']+'</form></div></div><div style="clear:both;padding:10px;float:right;"><div id="sgEditSave" class="btn btn-right"><div class="btn-text"><img src="[+manager_url+]media/style/[+theme+]/images/icons/save.png">'+_sgLang['save']+'</div></div><div id="sgEditCancel" class="btn btn-right"><div class="btn-text"><img src="[+manager_url+]media/style/[+theme+]/images/icons/stop.png">'+_sgLang['cancel']+'</div></div></div></div>');
			editForm.window({
    			modal:true,
    			title:sgHelper.escape(this.stripText(data.sg_title,80)),
    			doSize:true,
    			collapsible:false,
    			minimizable:false,
    			maximizable:false,
    			resizable:false,
    			onOpen: function() {
    				$('#sgEditCancel').click(function(e){
    					$('#sgEdit').window('close',true);
    				});
    				$('#sgEditSave').click(function(e){
    					$.post(
						"[+url+]?mode=edit", 
						$('#sgForm').serialize(),
						function(data) {
							data = $.parseJSON(data);
							if(data.success) {
								$('#sgEdit').window('close',true);
								$('#sg_pages').pagination('select');
							} else {
								$.messager.alert(_sgLang['error'],_sgLang['save_fail']);
							}
						})
    				})
    			},
    			onClose: function() {
    				$('#sgEdit').window('destroy',true);
    				$('.window-shadow,.window-mask').remove();
    			}
    		});
		},
		bytesToSize: function(bytes) {
		   if(bytes == 0) return '0 байт';
		   var k = 1024;
		   var sizes = ['байт', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
		   var i = Math.floor(Math.log(bytes) / Math.log(k));
		   return (bytes / Math.pow(k, i)).toPrecision(3) + ' ' + sizes[i];
		},
		stripText: function(str,len) {
			str.replace(/<\/?[^>]+>/gi, '');
			if (str.length > len) str = str.slice(0,len) + '...';
			return str;
		},
		escape: function(str) {
			return str
			    .replace(/&/g, '&amp;')
			    .replace(/>/g, '&gt;')
			    .replace(/</g, '&lt;')
			    .replace(/"/g, '&quot;');
		},
		refresh: function() {
			$.messager.confirm(_sgLang['refresh_previews'],_sgLang['are_you_sure_to_refresh'],function(r){
    			if (r){
        			$.post(
						"[+url+]?mode=refresh", 
						{},
						function(data) {
							data = $.parseJSON(data);
							
						}
					);
    			}
			});
		}
	}
	$(window).load(function(){
    	if ($('#sg-tab')) {
    		$('#sg-tab.selected').trigger('click');    
		}
	})
	$(document).ready(function() {
		$('#sg-tab').click(function(){
    		if (sgLoaded) {
        		$('#sg_pages').pagination('select');
    		} else {
        		sgHelper.init();
        		$('#sg_pages').pagination('select');
        		sgLoaded = true;
    		}
		})
	})
})(jQuery);
</script>
<div id="SimpleGallery" class="tab-page" style="display:none;width:100%;-moz-box-sizing: border-box; box-sizing: border-box;">
<h2 class="tab" id="sg-tab">[+tabName+]</h2>
</div>