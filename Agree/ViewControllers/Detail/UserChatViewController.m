//
//  UserChatViewController.m
//  Agree
//
//  Created by G4ddle on 15/3/24.
//  Copyright (c) 2015 superRabbit. All rights reserved.
//

#import "UserChatViewController.h"
#import "Model_User_Chat.h"
#import "SRImageManager.h"
#import "SRNet_Manager.h"
#import "MJExtension.h"
#import <SVProgressHUD.h>
#import "UserChatTableViewCell.h"
#import "AppDelegate.h"
#import "EaseMob.h"
#import "EModel_User_Chat.h"
#import "EMSendMessageHepler.h"
#import "SRKeyboard.h"
#import "SRTool.h"

#import <MJRefresh.h>


#define kLoadChatData       1
#define kSendMessage        2

@interface UserChatViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, EMChatManagerDelegate,UITableViewDelegate,UIScrollViewDelegate> {
    
    SRKeyboard *_srKeyBoard;
    UIImagePickerController *_imagePicker;
    
    UIImage *_chatPickImage;
    NSString *_imageName;
    
    Model_User_Chat *_userChat;
    NSMutableArray *_chatArray;
    
    NSMutableArray * _mchatArray;
    
    
    EMConversation *_conversation;
    
    
    UserChatTableViewCell *_longTapCell;
    UIView * HeadView;
    
    float tableCellHeight;
    
    int _page;
    int _pageSize;
    
    UILabel * _closelable;
    

}

@end


@implementation UserChatViewController

- (void)viewDidLayoutSubviews {
//    NSLog(@"%f", self.userChatTableView.contentSize.height);
    [_closelable setFrame:CGRectMake(0, self.userChatTableView.contentSize.height + self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, 50)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    NSLog(@"%f", self.userChatTableView.contentSize.height);
    // Do any additional setup after loading the view.
    self.accountView = [[SRAccountView alloc] init];
    
    self.accountView.rootController = self;
    //
   self.automaticallyAdjustsScrollViewInsets = false;
    
    
    //初始加载消息页数以及条数
    _page = 1;
    _pageSize = 10;

    
#pragma mark -- 创建上拉关闭的LABLE
    //创建在TABLEVIEW上
    _closelable = [[UILabel alloc]init];
    _closelable.text = @"继续上拉当前页";
    [_closelable setTextAlignment:NSTextAlignmentCenter];
    _closelable.textColor = [UIColor darkGrayColor];
    //缩小提示显示字号避免分散注意力
    [_closelable setFont:[UIFont systemFontOfSize:14]];
    [_closelable setAlpha:0.0];
    [_userChatTableView addSubview:_closelable];
    _userChatTableView.backgroundColor = [UIColor clearColor];
    
    
    //读取私信的消息列表
    _conversation = [[EaseMob sharedInstance].chatManager conversationForChatter:self.user.pk_user.stringValue conversationType:(eConversationTypeChat)];
    NSArray *messages = [_conversation loadAllMessages];
    
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
    
    //可变数组
    _chatArray = [[NSMutableArray alloc] init];
    for (EMMessage *message in messages) {
        EModel_User_Chat *chat;
        if ([self.user.pk_user.stringValue isEqualToString:message.from]) {
            //对方发的信息
            chat = [EModel_User_Chat repackEmessage:message withSender:self.user];
        } else {
            //自己发的信息
            Model_User *user = [[Model_User alloc] init];
            user.pk_user = [Model_User loadFromUserDefaults].pk_user;
            user.nickname = [Model_User loadFromUserDefaults].nickname;
            user.avatar_path = [Model_User loadFromUserDefaults].avatar_path;
            chat = [EModel_User_Chat repackEmessage:message withSender:user];
        }
        [_chatArray addObject:chat];
    }
    
    [self subChatArray];

    
    
#pragma mark -- 导航栏标题
    [self.navigationItem setTitle:self.user.nickname];
    
    //聊天信息切换到最底层显示
    
    if (messages.count == 0) {
        return;
    }
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:_mchatArray.count-1  inSection:0];
    [self tableViewIsScrollToBottom:YES withAnimated:NO];
    [self.userChatTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    [_conversation markAllMessagesAsRead:YES];
}



- (void)subChatArray {
    if (_chatArray.count > _pageSize) {
        _mchatArray = [NSMutableArray arrayWithArray:[_chatArray subarrayWithRange:NSMakeRange(_chatArray.count - (_mchatArray.count+_pageSize),_mchatArray.count+_pageSize)]];
    } else {
        _mchatArray = [[NSMutableArray alloc] initWithArray:_chatArray];
    }
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _srKeyBoard = [[SRKeyboard alloc] init];
    [_srKeyBoard textViewShowView:self
           customKeyboardDelegate:self
                     withMoveView:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _srKeyBoard = nil;
}


- (void)didReceiveMessage:(EMMessage *)message {
    [_conversation markAllMessagesAsRead:YES];
    if ([message.from isEqualToString:self.user.pk_user.stringValue]) {
        EMError *error = nil;
        message = [[EaseMob sharedInstance].chatManager fetchMessageThumbnail:message progress:nil error:&error];
        //这里将自动下载附件
        if (!error) {
            //完成
        }
        EModel_User_Chat *chat = [EModel_User_Chat repackEmessage:message withSender:self.user];
        
        if (chat) {
            [_mchatArray addObject:chat];
            [_chatArray addObject:chat];
        }
//        [self subChatArray];
        [self.userChatTableView reloadData];
    }
    //聊天信息切换到最底层显示
    [self tableViewIsScrollToBottom:YES withAnimated:YES];
}

- (IBAction)tapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (_mchatArray) {
        return (_mchatArray.count);
    } else {
        return 0;
    }
    

}

//Cell内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     static NSString *kCellIdentifier = @"UserChatCell";
    UserChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    EModel_User_Chat *chat = [_mchatArray objectAtIndex:indexPath.row];
    if (nil == cell) {
        cell = [[UserChatTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }


    [cell setTopViewController:self];
    [cell initWithChat:chat];
    
    

    UILongPressGestureRecognizer * longPressGesture =  [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(cellLongPress:)];
    
    
    id<IEMMessageBody> msgBody = chat.message.messageBodies.firstObject;
    
    switch (msgBody.messageBodyType) {
        case eMessageBodyType_Text: {
            //文本
            if (chat.sendFromSelf) {
                //自己发言
                [cell.messageBackgroundButton_self addGestureRecognizer:longPressGesture];
                
            } else {
                //他人发的信息
                [cell.messageBackgroundButton addGestureRecognizer:longPressGesture];
            }
        }
            break;
        case eMessageBodyType_Image: {
            //图片
            if (chat.sendFromSelf) {
                
                
            } else {
            //他人发的图片

            }
        }
        default:
            break;
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}


//CELL自适应消息高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //message内容
    EModel_User_Chat *message = [_mchatArray objectAtIndex:indexPath.row];
    
    return [self cellHeightFromMessage:message].floatValue;
}


//
- (NSNumber *)cellHeightFromMessage:(EModel_User_Chat *)message {
    id<IEMMessageBody> msgBody = message.message.messageBodies.firstObject;
    
    switch (msgBody.messageBodyType) {
        case eMessageBodyType_Text: {
            //文本
            if (!((EMTextMessageBody *)msgBody).text.length) {
                ((EMTextMessageBody *)msgBody).text = @"  ";
            }
            if (message.sendFromSelf) {
                //自己发的信息
                //自己发言
                UILabel *chatLabel_self = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width - 185, MAXFLOAT)];

                [chatLabel_self setFont:[UIFont systemFontOfSize:14]];
                [chatLabel_self setLineBreakMode:NSLineBreakByWordWrapping];
                [chatLabel_self setTextAlignment:NSTextAlignmentLeft];
                [chatLabel_self setNumberOfLines:0];
                
                
                chatLabel_self.text = ((EMTextMessageBody *)msgBody).text;
                //在这里进行宽度的测算
                NSDictionary *attribute = @{NSFontAttributeName: chatLabel_self.font};
                CGSize wSize = [((EMTextMessageBody *)msgBody).text boundingRectWithSize:chatLabel_self.frame.size options:NSStringDrawingTruncatesLastVisibleLine  attributes:attribute context:nil].size;
                
                if (!message.cell_width) {
                    [message setCell_width:[NSNumber numberWithFloat:wSize.width + 2.0]];
                }
                
                CGSize size = [chatLabel_self sizeThatFits:chatLabel_self.frame.size];
                
                return [NSNumber numberWithFloat:size.height + 45.0];
            } else {
                //他人发的信息
                UILabel *chatLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width - 132, MAXFLOAT)];
                
                [chatLabel setFont:[UIFont systemFontOfSize:14]];
                [chatLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [chatLabel setTextAlignment:NSTextAlignmentLeft];
                [chatLabel setNumberOfLines:0];
                
                chatLabel.text = ((EMTextMessageBody *)msgBody).text;
                //在这里进行宽度的测算
                NSDictionary *attribute = @{NSFontAttributeName: chatLabel.font};
                CGSize wSize = [((EMTextMessageBody *)msgBody).text boundingRectWithSize:chatLabel.frame.size options:NSStringDrawingTruncatesLastVisibleLine  attributes:attribute context:nil].size;
                
                if (!message.cell_width) {
                    [message setCell_width:[NSNumber numberWithFloat:wSize.width + 2.0]];
                }
                
                //在这里进行高度的测算
                CGSize size = [chatLabel sizeThatFits:CGSizeMake([[UIScreen mainScreen] bounds].size.width - 132, MAXFLOAT)];
                return [NSNumber numberWithFloat:size.height + 50.0];
            }
        }
            break;
        case eMessageBodyType_Image: {
            //图片
            EMImageMessageBody *body = ((EMImageMessageBody *)msgBody);
            if (message.sendFromSelf) {
                //自己发的图片
                
                //设置行高为图片标准高度
                return [NSNumber numberWithFloat:body.thumbnailSize.height/2 + 40.0];
            } else {
                //他人发的图片
                return [NSNumber numberWithFloat:body.thumbnailSize.height + 45.0];
            }
        }
        default:
            return 0;
            break;
    }
}



#pragma mark - key board
- (void)talkBtnClick:(UITextView *)textViewGet {
    
    if (0 != textViewGet.text.length) {
        [self sendMessageFromString:textViewGet.text];
        
    }
}


//输入框左边BUTTON（图片发送选择)
- (void)imageBtnClick {
    //点击图片按钮
    if (!_imagePicker) {
        _imagePicker = [[UIImagePickerController alloc] init];
        [_imagePicker setDelegate:self];
        _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;

    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [SRTool showSRSheetInView:self.view withTitle:@"选择图片来源" message:nil
                  withButtonArray:@[@"拍照", @"相册"]
                  tapButtonHandle:^(int buttonIndex) {
                      UIImagePickerControllerSourceType sourceType;
                      switch (buttonIndex) {
                          case 0: {
                              //拍照
                              sourceType = UIImagePickerControllerSourceTypeCamera;
                          }
                              break;
                          case 1: {
                              //相册
                              sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                          }
                              break;
                          default:
                              break;
                      }
                      _imagePicker.sourceType = sourceType;
                      [self presentViewController:_imagePicker animated:YES completion:nil];
                  } tapCancelHandle:^{
                      
                  }];
    } else {
        _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:_imagePicker animated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    _chatPickImage = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
    
    [SRTool showSRAlertViewWithTitle:@"提示"
                             message:@"真的要发送这张图片吗?"
                   cancelButtonTitle:@"我再想想"
                    otherButtonTitle:@"是的"
               tapCancelButtonHandle:^(NSString *msgString) {
                   
               } tapOtherButtonHandle:^(NSString *msgString) {
                   [self sendImage];
               }];
}

- (void)sendImage {
    [self sendMessageDone:[EMSendMessageHepler sendImageMessageWithImage:_chatPickImage
                                                              toUsername:self.user.pk_user.stringValue
                                                             isChatGroup:NO
                                                       requireEncryption:NO
                                                                     ext:nil]];
}


- (void)sendMessageFromString: (NSString *)text {

    
    [self sendMessageDone:[EMSendMessageHepler sendTextMessageWithString:text
                                                              toUsername:self.user.pk_user.stringValue
                                                             isChatGroup:NO
                                                       requireEncryption:NO
                                                                     ext:nil]];

}

- (void)sendMessageDone:(EMMessage *)message {
    //自己发的信息

    Model_User *selfAccount = [Model_User loadFromUserDefaults];
    
    //将信息输入数组,并刷新
    EModel_User_Chat *chat = [EModel_User_Chat repackEmessage:message withSender:selfAccount];
    [_chatArray addObject:chat];
    [_mchatArray addObject:chat];
    [self.userChatTableView reloadData];
    [self tableViewIsScrollToBottom:YES withAnimated:YES];
    
    
    Model_User_Chat *newChat = [[Model_User_Chat alloc] init];
    [newChat setFk_user_from:selfAccount.pk_user];
    [newChat setFk_user_to:self.user.pk_user];
    [newChat setNickname_from:selfAccount.nickname];
    [newChat setNickname_to:self.user.nickname];
    
    id<IEMMessageBody> msgBody = message.messageBodies.firstObject;
    switch (msgBody.messageBodyType) {
        case eMessageBodyType_Text: {
            newChat.content = ((EMTextMessageBody *)msgBody).text;
        }
            break;
        case eMessageBodyType_Image: {
            newChat.content = @"[图片]";
        }
            break;
        default:
            break;
    }
    
    [SRNet_Manager requestNetWithDic:[SRNet_Manager addUserChatDic:newChat]
                            complete:^(NSString *msgString, id jsonDic, int interType, NSURLSessionDataTask *task) {
                                
                            } failure:^(NSError *error, NSURLSessionDataTask *task) {
                                
                            }];
    
}

- (void)tableViewIsScrollToBottom: (BOOL) isScroll
                     withAnimated: (BOOL)isAnimated {
    
    float headHight = 0;
    for (EModel_User_Chat *message in _mchatArray) {
        headHight += [self cellHeightFromMessage:message].floatValue;
    }
    
    headHight = self.userChatTableView.frame.size.height - headHight;
    if (headHight <= 0) {
        headHight = 0;
    }
    
    self.userChatTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.userChatTableView.frame.size.width, headHight)];
    if (isScroll) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger s = [self.userChatTableView numberOfSections];
            if (s<1) return;
            NSInteger r = [self.userChatTableView numberOfRowsInSection:s-1];
            if (r<1) return;
            NSIndexPath *ip = [NSIndexPath indexPathForRow:r-1 inSection:s-1];
            
            [self.userChatTableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:isAnimated];
        });
    }
}


//详情BUTTON
- (IBAction)tapDetailButton:(id)sender {
    [SRTool showSRSheetInView:self.view
                    withTitle:@"详细" message:@"选择想要做的操作"
              withButtonArray:@[@"好友资料", @"支付款项"]
              tapButtonHandle:^(int buttonIndex) {
                  switch (buttonIndex) {
                      case 0: {
                          if (![self.user.pk_user isEqual:[Model_User loadFromUserDefaults].pk_user]) {
                              [self.accountView loadWithUser:self.user withGroup:nil];
                              [self.accountView show];
                          }
                      }
                          break;
                      case 1: {
                          [SRTool showSRAlertViewWithTitle:@"提示"
                                                   message:@"我们很快将会开通资金支付的功能,请各位小伙伴耐心等待哦~"
                                         cancelButtonTitle:@"好的"
                                          otherButtonTitle:nil
                                     tapCancelButtonHandle:^(NSString *msgString) {
                                         
                                     } tapOtherButtonHandle:^(NSString *msgString) {
                                         
                                     }];
                      }
                          break;
                      default:
                          break;
                  }
              } tapCancelHandle:^{
                  
              }];
    
}


#define mark 聊天信息的操作方法
- (void)cellLongPress:(UIGestureRecognizer *)recognizer{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        CGPoint location = [recognizer locationInView:self.userChatTableView];
        NSIndexPath * indexPath = [self.userChatTableView indexPathForRowAtPoint:location];
        //        UserChatTableViewCell *cell = (UserChatTableViewCell *)recognizer.view;
        UserChatTableViewCell *cell = (UserChatTableViewCell *)[self.userChatTableView cellForRowAtIndexPath:indexPath];
        [cell becomeFirstResponder];
        _longTapCell = nil;
        _longTapCell = cell;
        
        UIMenuItem *itCopy = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(handleCopyCell:)];
        UIMenuItem *itReSend = [[UIMenuItem alloc] initWithTitle:@"再次发送" action:@selector(handleResendCell:)];
        UIMenuController *menu = [UIMenuController sharedMenuController];
        [menu setMenuItems:[NSArray arrayWithObjects:itCopy,itReSend, nil]];

        EModel_User_Chat *chat = [_mchatArray objectAtIndex:indexPath.row];
        
        
        id<IEMMessageBody> msgBody = chat.message.messageBodies.firstObject;
        
        switch (msgBody.messageBodyType) {
            case eMessageBodyType_Text: {
                //文本
                if (chat.sendFromSelf) {
                    //自己发言
                    [menu setTargetRect:CGRectMake(cell.chatMessageBackground_self.frame.origin.x, cell.frame.origin.y + 30, cell.messageBackgroundButton_self.frame.size.width, cell.messageBackgroundButton_self.frame.size.height) inView:self.userChatTableView];
                    
                } else {
                    //他人发的信息
                    [menu setTargetRect:CGRectMake(cell.chatMessageBackground.frame.origin.x, cell.frame.origin.y + 30, cell.messageBackgroundButton.frame.size.width, cell.messageBackgroundButton.frame.size.height) inView:self.userChatTableView];
                }
            }
                break;
            case eMessageBodyType_Image: {
                //图片
                if (chat.sendFromSelf) {
                    
                    
                } else {
                    //他人发的图片
                    
                }
            }
            default:
                break;
        }
        
        [menu setMenuVisible:YES animated:YES];
    }
}

- (void)handleCopyCell:(id)sender
{
    NSLog(@"复制");


    UIPasteboard *pboard = [UIPasteboard generalPasteboard];
    
    if (!_longTapCell.chatMessageTextLabel_self.isHidden ) {
        pboard.string = _longTapCell.chatMessageTextLabel_self.text;
    }else
    {
        pboard.string = _longTapCell.chatMessageTextLabel.text;
    }
    
    //复制出的内容
    NSLog(@"%@",pboard.string);
 
}

- (void)handleResendCell:(id)sender {
    NSLog(@"handle resend cell");
    
    UIPasteboard *pboard = [UIPasteboard generalPasteboard];
    
    if (!_longTapCell.chatMessageTextLabel_self.isHidden ) {
        pboard.string = _longTapCell.chatMessageTextLabel_self.text;
    }else
    {
        pboard.string = _longTapCell.chatMessageTextLabel.text;
    }
   
    
    [self sendMessageFromString:pboard.string];
    
    //复制出的内容
    NSLog(@"%@",pboard.string);
}


- (BOOL)canBecomeFirstResponder{
    return YES;
}

#pragma mark -- 上下拉刷新
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
#pragma mark -- 下拉加载数据

    float contentoffsetY = _userChatTableView.contentOffset.y;
    
//    float contentsizeH = self.userChatTableView.contentSize.height;

    //判断如果下拉超过限定 就加载数据
    if (( 0 == (contentoffsetY))&&!(_mchatArray.count == _chatArray.count) ){
        NSLog(@"下拉到顶刷新");
        _page++;
        [self subChatArray];
        [self.userChatTableView reloadData];
        
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:10  inSection:0];
        [self.userChatTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        
        //在下拉加载时更改关闭提示的高度,以保持在列表最底端
        [_closelable setFrame:CGRectMake(0, self.userChatTableView.contentSize.height + self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, 50)];
        
    }
    //默认一次10个 这是最后一次加载大于0小于10的个数
    else if( _chatArray.count - _mchatArray.count > 0 && _chatArray.count - _mchatArray.count < 10  ){

        _mchatArray = [[NSMutableArray alloc]initWithArray:_chatArray];
        [self.userChatTableView reloadData];

    }else if( _mchatArray.count == _chatArray.count )
    {
        NSLog(@"数组已经加载结束 停止加载");

    }
    
    
//    float draggingGetPoint = [UIScreen mainScreen].bounds.size.height - 220;
//    
//    if ((contentsizeH - contentoffsetY) < self.userChatTableView.frame.size.height) {
//        //超过了列表的最底端,关闭提示开始进行显示
//        
//        //超出列表拖移的长度
//        float draggingLager = self.userChatTableView.frame.size.height - (contentsizeH - contentoffsetY);
//        //根据拖移的位置来更改label透明度
//        _closelable.alpha = (draggingLager - self.navigationController.navigationBar.frame.size.height - 20)/(self.userChatTableView.frame.size.height - draggingGetPoint - self.navigationController.navigationBar.frame.size.height - 20);
//        
//        
//    } else {
//        //如果没有超过最底端,则不进行提示展示
//        _closelable.alpha = 0.0;
//        
//        _closelable.text = @"继续上拉当前页";
//    }
//    
//    if ((self.userChatTableView.contentSize.height - self.userChatTableView.contentOffset.y) <  draggingGetPoint) {
//        //如果拖移位置超过预定点,更改提示文字
//        _closelable.text = @"释放关闭当前页";
//    } else {
//        _closelable.text = @"继续上拉当前页";
//    }

}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//
//    //根据屏幕的高度来自适应拖移关闭的高度
//    float draggingGetPoint = [UIScreen mainScreen].bounds.size.height - 220;
//          
//    if ((self.userChatTableView.contentSize.height - self.userChatTableView.contentOffset.y) <  draggingGetPoint) {
//        //如果拖移位置超过预定点,则推出视图
//        [self.navigationController popViewControllerAnimated:YES];
//    }
//}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */





@end
