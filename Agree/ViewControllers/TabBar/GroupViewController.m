//
//  GroupViewController.m
//  Agree
//
//  Created by G4ddle on 15/2/14.
//  Copyright (c) 2015年 superRabbit. All rights reserved.
//

#import "GroupViewController.h"
#import "GroupCollectionViewCell.h"
#import <SVProgressHUD.h>
#import "MJExtension.h"
#import "GroupDetailViewController.h"
#import "AppDelegate.h"
#import "UIImageView+WebCache.h"
#import "SRImageManager.h"

#import "EaseMob.h"
#import "CD_Group.h"
#import <MJRefresh.h>

#import <DQAlertView.h>

@interface GroupViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, IChatManagerDelegate> {
    NSUInteger _chooseIndexPath;
}


@end

@implementation GroupViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //先读取缓存中的小组信息
    self.groupAry = [CD_Group getGroupFromCD];
    
    [self loadUserGroupRelationship];
    
    //在程序的代理中进行注册
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate setGroupDelegate:self];
    
    
    //注册代理
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
    
    if ([Model_User loadFromUserDefaults].pk_user) {
        //开始自动登录
        //自动设置并判断登录
        BOOL isAutoLogin = [[EaseMob sharedInstance].chatManager isAutoLoginEnabled];
        if (!isAutoLogin) {
            [[EaseMob sharedInstance].chatManager asyncLoginWithUsername:[Model_User loadFromUserDefaults].pk_user.stringValue
                                                                password:@"paopian"
                                                              completion:^(NSDictionary *loginInfo, EMError *error) {
                                                                  if (!error) {
                                                                      //设置自动登录
                                                                      //登录成功
                                                                      [[EaseMob sharedInstance].chatManager setIsAutoLoginEnabled:YES];
                                                                  }
                                                              } onQueue:nil];
        }
    }
    
    //设置初始可滚动,这样才能激活刷新的方法
    self.groupCollectionView.alwaysBounceVertical = YES;
    // 设置回调（一旦进入刷新状态，就调用target的action，也就是调用self的loadNewData方法）
    self.groupCollectionView.header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh:)];
}

- (void)refresh: (id)sender {
    //开始刷新
    [self.groupCollectionView.header endRefreshing];
}


/*!
 @method
 @brief 用户自动登录完成后的回调
 @discussion
 @param loginInfo 登录的用户信息
 @param error     错误信息
 @result
 */
- (void)didAutoLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error; {
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshUpdateInfo];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.codeView setHidden:YES];
    
    [self pressedTheRecodeButton:nil];
    [self.codeInputTextField setText:nil];
    [self.codeInputTextField resignFirstResponder];
    [super viewWillDisappear:animated];
}

- (void)refreshUpdateInfo {
    if (self.dataChange) {
        [self.groupCollectionView reloadData];
        self.dataChange = FALSE;
    }
}

- (void)cleanAllPartyUpdate {
    for (Model_Group *group in self.groupAry) {
        [group setParty_update:@0];
    }
    self.dataChange = TRUE;
    [self refreshUpdateInfo];
}

- (void)addGroupChatUpdateStatus: (NSString *)em_id {
    for (Model_Group *group in self.groupAry) {
        if ([em_id isEqualToString:group.em_id]) {
            group.chat_update = [NSNumber numberWithInt:(group.chat_update.intValue + 1)];
            self.dataChange = TRUE;
        }
    }
    [self refreshUpdateInfo];
}

- (void)addGroupPartyUpdateStatus: (NSNumber *)pk_group {
    for (Model_Group *group in self.groupAry) {
        if ([pk_group isEqualToNumber:group.pk_group]) {
            group.party_update = [NSNumber numberWithInt:(group.party_update.intValue + 1)];
            self.dataChange = TRUE;
        }
    }
    [self refreshUpdateInfo];
}

- (void)loadUserGroupRelationship {
    Model_User *user = [[Model_User alloc] init];
    user.pk_user = [Model_User loadFromUserDefaults].pk_user;
    
    [SRNet_Manager requestNetWithDic:[SRNet_Manager getUserGroupsDic:user]
                            complete:^(NSString *msgString, id jsonDic, int interType, NSURLSessionDataTask *task) {
                                if (jsonDic) {
                                    //判断小组数据是否有更新,是否需要刷新列表
                                    NSMutableArray *tempAry = [NSMutableArray arrayWithArray:[Model_Group objectArrayWithKeyValuesArray:jsonDic]];
                                    
                                    BOOL isSave = YES;
                                    if (tempAry.count == self.groupAry.count) {
                                        //小组数据的数量一样,开始进行数据比对
                                        for (Model_Group *theGroup in tempAry) {
                                            //这里暂时只对小组的id进行比对
                                            Model_Group *otherGroup = [self.groupAry objectAtIndex:[tempAry indexOfObject:theGroup]];
                                            if (![theGroup.pk_group isEqual:otherGroup.pk_group]) {
                                                isSave = NO;
                                            }
                                        }
                                    } else {
                                        //小组数据的数量不一样
                                        isSave = NO;
                                    }
                                    
                                    //小组有更新,开始更新步骤
                                    //将缓存的数组全部删除
                                    [CD_Group removeAllGroupFromCD];
                                    for (Model_Group *group in self.groupAry) {
                                        [CD_Group saveGroupToCD:group];
                                    }
                                    
                                    if (!isSave) {
                                        //小组数据有更新的情况下在进行界面上的刷新
                                        self.groupAry = nil;
                                        self.groupAry = tempAry;
                                        [self.groupCollectionView reloadData];
                                    }
                                } else {
                                    //没有加入的小组信息
                                    //将缓存的数组全部删除
                                    [self.groupAry removeAllObjects];
                                    [CD_Group removeAllGroupFromCD];
                                    [self.groupCollectionView reloadData];
                                }
                            } failure:^(NSError *error, NSURLSessionDataTask *task) {

                            }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.groupAry) {
        return self.groupAry.count + 1;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GroupCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GroupCollectionCell" forIndexPath:indexPath];

    if (indexPath.row == self.groupAry.count) {
        //最后一条信息
        //添加聚会按钮
        [cell initCellWithGroup:nil isAddView:YES];
    } else {
        
        Model_Group *theGroup = [self.groupAry objectAtIndex:indexPath.row];
        if (!cell.chatUpdate) {
            cell.chatUpdate = YES;
            EMConversation *conversation = [[EaseMob sharedInstance].chatManager conversationForChatter:theGroup.em_id conversationType:eConversationTypeGroupChat];
            [theGroup setChat_update:[NSNumber numberWithInteger:conversation.unreadMessagesCount]];
        }
        [cell initCellWithGroup:theGroup isAddView:NO];
    }
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionFooter){
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        
        reusableview = footerView;
    }
    
    return reusableview;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float widthFloat = ([[UIScreen mainScreen] bounds].size.width - 3)/2;
    return CGSizeMake(widthFloat, widthFloat);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _chooseIndexPath = indexPath.row;
    return TRUE;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if (_chooseIndexPath == self.groupAry.count) {
        //新建页面
        [self performSegueWithIdentifier:@"CreateGroup" sender:self];
        _chooseIndexPath = 0;
        return NO;
    }
    if ([identifier isEqualToString:@"CreateGroup"]) {
        if (!self.codeView.hidden) {
            //正在输入邀请码
            self.codeView.hidden = YES;
            [self.codeInputTextField resignFirstResponder];
            [self.createButton setTitle:@"新建" forState:UIControlStateNormal];
            return NO;
        } else {
            return YES;
        }
    }
    
    return YES;
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    //进入小组详情
    if ([@"GroupDetail"  isEqual: segue.identifier]) {
        //读取小组详情数据并赋值小组数据
        GroupDetailViewController *controller = (GroupDetailViewController *)segue.destinationViewController;
        controller.group = [self.groupAry objectAtIndex:_chooseIndexPath];
    }
}

- (IBAction)pressedCodeButton:(id)sender {
    if (self.codeView.hidden) {
        self.codeView.hidden = NO;
        [self.codeInputTextField becomeFirstResponder];
        [self.createButton setTitle:@"关闭" forState:UIControlStateNormal];
    } else {
        self.codeView.hidden = YES;
        [self.createButton setTitle:@"新建" forState:UIControlStateNormal];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //验证码输入界面
    Model_Group_Code *newCode = [[Model_Group_Code alloc] init];
    newCode.pk_group_code = textField.text;
    [SRNet_Manager requestNetWithDic:[SRNet_Manager joinTheGroupByCodeDic:newCode]
                            complete:^(NSString *msgString, id jsonDic, int interType, NSURLSessionDataTask *task) {
                                if (jsonDic) {
                                    [SVProgressHUD showSuccessWithStatus:@"找到小组"];
                                    self.joinGroup = [[Model_Group objectArrayWithKeyValuesArray:jsonDic] firstObject];
                                    
                                    //显示要加入的小组
                                    [self.groupCoverImageView setHidden:NO];
                                    [self.groupNameLabel setHidden:NO];
                                    [self.recodeButton setHidden:NO];
                                    [self.joinButton setHidden:NO];
                                    [self.publicPhoneLabel setHidden:NO];
                                    [self.publicPhoneSeg setHidden:NO];
                                    
                                    [self.codeInputTextField setHidden:YES];
                                    //            [self.groupCoverButton setHidden:YES];
                                    [self.remarkLabel setHidden:YES];
                                    
                                    [self.groupNameLabel setText:_joinGroup.name];
                                    
                                    //下载图片
                                    NSURL *imageUrl = [SRImageManager groupFrontCoverImageImageFromOSS:_joinGroup.avatar_path];
                                    
                                    [self.groupCoverImageView sd_setImageWithURL:imageUrl];
                                } else {
                                    [SVProgressHUD showSuccessWithStatus:@"未找到相关数据"];
                                    //未找到小组的相关数据
                                    [self.remarkLabel setText:@"未找到小组信息,请再次确认输入"];
                                    [self.codeInputTextField becomeFirstResponder];
                                }
                            } failure:^(NSError *error, NSURLSessionDataTask *task) {
                                
                            }];
    
    [textField resignFirstResponder];

    return YES;
}
- (IBAction)pressedCodeBackButton:(id)sender {
    [self.codeInputTextField resignFirstResponder];
    [self.codeView setHidden:YES];
    [self.createButton setTitle:@"新建" forState:UIControlStateNormal];
}

- (void)joinGroupRelation {
    [[EaseMob sharedInstance].chatManager asyncJoinPublicGroup:self.joinGroup.em_id completion:^(EMGroup *group, EMError *error) {
        if (!error || [error.description isEqualToString:@"Group has already joined."]) {
            //将创建者加入关系
            Model_Group_User *group_user = [[Model_Group_User alloc] init];
            [group_user setFk_group:self.joinGroup.pk_group];
            [group_user setFk_user:[Model_User loadFromUserDefaults].pk_user];
            //1.创建者 2.普通成员
            [group_user setRole:[NSNumber numberWithInt:2]];
            if (self.needPublicPhone) {
                [group_user setPublic_phone:@1];
            } else {
                [group_user setPublic_phone:@0];
            }
            [SRNet_Manager requestNetWithDic:[SRNet_Manager joinGroupDic:group_user]
                                    complete:^(NSString *msgString, id jsonDic, int interType, NSURLSessionDataTask *task) {
                                        [self loadUserGroupRelationship];
                                    } failure:^(NSError *error, NSURLSessionDataTask *task) {
                                        
                                    }];
        }
    } onQueue:nil];
    
    [self.codeView setHidden:YES];
    [self.createButton setTitle:@"新建" forState:UIControlStateNormal];
}


- (IBAction)pressedTheJoinButton:(id)sender {
    if (0 == self.publicPhoneSeg.selectedSegmentIndex) {
        //公开
        self.needPublicPhone = YES;
    } else {
        //不公开
        self.needPublicPhone = NO;
    }
    [self joinGroupRelation];
}


//新建小组BUTTON
- (IBAction)pressedTheRecodeButton:(id)sender {
    //重新输入验证码
    [self.groupNameLabel setText:@""];
    [self.groupCoverImageView setImage:nil];
    
    [self.groupCoverImageView setHidden:YES];
    [self.groupNameLabel setHidden:YES];
    [self.recodeButton setHidden:YES];
    [self.joinButton setHidden:YES];
    [self.publicPhoneLabel setHidden:YES];
    [self.publicPhoneSeg setHidden:YES];
    
    [self.codeInputTextField setHidden:NO];
//    [self.groupCoverButton setHidden:NO];
    [self.remarkLabel setHidden:NO];
    
    if (sender) {
        [self.codeInputTextField becomeFirstResponder];
    }
}

- (void)intoChatView {
    [self.navigationController.tabBarController setSelectedIndex:2];
}

- (void)setGroupAvatar: (UIImage *)image atIndex: (NSIndexPath *)indexPath {
    GroupCollectionViewCell *cell = (GroupCollectionViewCell *)[self.groupCollectionView cellForItemAtIndexPath:indexPath];
    [cell.groupImageView setImage:image];
}

@end
