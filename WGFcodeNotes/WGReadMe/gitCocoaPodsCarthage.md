# Git学习心得
## 一.配置
1. 在本地创建一个新的工程项目，项目名称:WGGitLearnProject，打开命令行，cd到该目录下 
2. git init                                                                              :初始化一个空的git仓库
3. git config --global user.name "WGFcode"                       :配置github的用户名称
4. git config --global user.email "1813061716@qq.com"   :配置github的用户邮箱
5. git add .                                                                           :将本地项目添加到git的暂存区  
6. git commit -m "功能描述"                   :初始化本地项目并添加到git本地仓库" 
7. git remote add origin https://github.com/WGFcode/WGFcodeNotes.git   :初次添加到GitHub上需要和Github上的项目地址绑定
8.git branch -M main           :新版本的主分支都叫main，而不是master
9. git push -u origin master                       :将项目推送的远程仓库
10. 如果是从仓库中拷贝代码到本地，在本地创建空的文件，然后使用git clone https://github.com/WGFcode/WGFcodeNotes.git 将远程仓库代码拷贝到本地创建的空文件中

#3. 命令行释意
#工作区

    1.git status             :查看当前工作区的状态，告诉你哪些文件被修改过
    2.git diff               :查看工程中被修改的内容
      git diff 文件1路径       :查看文件1被修改的内容
    3.git checkout .         :丢弃工作区中的所有修改，回到最初状态
      git checkout -- 文件1路径  :丢弃工作区中文件1路径下文件的所有修改 ，回到最初状态
      
#暂存区(已经执行了git add命令)

    1.git add .          :提交部分变化(被修改、添加的新文件，不包括被删除的文件)到暂存区
      git add 文件1路径    :将工作区的某一个文件的修改添加到暂存区
      git add -A         :提交所有变化(被修改、添加的新文件、删除的文件)到暂存区
      git add -u         :提交部分变化(被修改、被删除的文件，不包括新文件)到暂存区
    2.git diff --cached   :查看暂存区和工作区的区别(查看修改内容)
      git diff --cached 文件1路径 :查看文件1的暂存区与工作区的区别
    3.git reset head 文件1路径  :将添加到暂存区的文件1回退到工作区，注意文件1中的修改代码在工作区还存在，  
    只是文件1不在暂存区了，如果想丢弃工作区文件1的修改，继续使用git checkout -- 文件1路径即可
    git reset head  :将添加到暂存区的全部文件回退到工作区，代码依然存在工作区，只是不再添加到暂存区了
#本地仓库(已经执行了git commit命令)

     1.即git add . 又git commit -m ""  此时代码已经添加到了本地仓库，但是并没有添加到远程仓库
     2.使用git log 查看历史版本，或者使用git reflog查看历史版本
             localhost:WGGitLearnProject wubaicai$ git log
             commit f190044a70110480d940d012ddd70f8c03854e2a (HEAD -> master)
             Author: baiaicaiai <1813061716@qq.com>
             Date:   Sun Aug 26 18:26:21 2018 +0800
             
             add UIButton
             
             commit 96954374b3e342c0c00e92648ed197015a5178d7
             Author: baiaicaiai <1813061716@qq.com>
             Date:   Sun Aug 26 18:22:13 2018 +0800
             
             add ViewController View is Red Color
             
             commit cbb928c10765f26f9108057bb27d4f70e6b95329 (origin/master)
             Author: baiaicaiai <1813061716@qq.com>
             Date:   Sun Aug 26 17:11:16 2018 +0800
             
             Location new project push to github
       3.git reset --hard 96954374b3e342c0c00e92648ed197015a5178d7
       将add UIButton版本回退到add ViewController View is Red Color的版本，
       此时工作区的代码都显示成了add ViewController View is Red Color版本时候的代码。
       如果想重新回到 add UIButton的版本，使用git reflog 
       localhost:WGGitLearnProject wubaicai$ git reflog
       9695437 (HEAD -> master) HEAD@{0}: reset: moving to 96954374b3e342c0c00e92648ed197015a5178d7
       f190044 HEAD@{1}: reset: moving to f190044a70110480d940d012ddd70f8c03854e2a
       f190044 HEAD@{2}: commit: add UIButton
       9695437 (HEAD -> master) HEAD@{3}: commit: add ViewController View is Red Color
       cbb928c (origin/master) HEAD@{4}: commit (initial): Location new project push to github
       localhost:WGGitLearnProject wubaicai$ git reset --hard f190044


#添加忽略项目部分文件改变的配置文件

    1.在工程目录中，touch .gitignore 创建配置文件(若不现实，使用ls -ah 显示隐藏文件)
    2.open .gitignore 打开配置文件，将https://github.com/github/gitignore/blob/master/Swift.gitignore中的内容复制粘贴
    3.添加到仓库中
    4.如果.gitignore规则不生效:先把本地缓存删除然后更新
    git rm -r --cached .
    5.在合并代码的时候，.DS_Store和.xcuserstate文件冲突无法合并解决方法
    (1)open .gitignore打开文件，添加.DS_Store和*.xcuserstate
    (2)git rm --cached .DS_Store  git rm --cached *.xcuserstate移除忽略这两个文件
    (3)然后git add .  git commit -m "更新gitignore"  git pull  git push
    (4)思考：为什么先git pull 再git push，这样仓库的代码会覆盖我本地代码呀！！！
       在多人开发中，pull是为了本地commit和远程commit进行对比，如果有冲突，git会把这个冲突标记出来，  
       这个时候需要先和最近一次push代码的人协商，解决冲突，然后在push，如果没有冲突git就直接将pull下来  
       的代码和本地进行合并了，不会覆盖代码
       代码覆盖或者丢失：小白和小黑本地都是刚pull下来的代码，然后小白本地修改了代码，并且push到了远程  
       (push1-push2),这时候小黑本地也修改了代码，但是没有commit,直接pull了小白的代码(push1-push2)到本地，  
       此刻小黑的本地代码已经到push2了，然后小黑继续修改，如果修改了小白写过的代码文件white1，然后进行了commit&push  
       到远程仓库push3,那么小白之前提交的white1文件就会被覆盖，所以多人开发一定要先commit,然后再pull,最后再push

#其它命令行分析

    1.git branch             :查看当前工程下的分支，当前分支前用*标记
      git branch -r          :查看远程版本库分支列表
      git branch -a          :查看所有分支列表，包括本地和远程
      git branch -m oldName newName   :给分支重命名,若newName已存在，则使用-M强制重命名
      git push --set-upstream origin branch1  :将分支推送到远程仓库
    2.git branch XX          :创建XX的分支名称
      git checkout XX        :切换到XX分支上
      git checkout -b XX     :创建并切换到XX分支上，相当于上面两条命令
    3.创建分支testBranch完成功能后，先切换到主分支上
        git checkout -b testBranch   :创建并切换到分支testBranch上，完成部分功能开发后
        git add .    git commit -m "完成分支上功能的开发了"
        git checkout master   :切到主分支上
        git merge testBranch   :将testBranch分支合并到当前分支(master分支)
    4.完成分支合并后，就可以删除分支了
        git branch -d testBranch  :删除本地分支testBranch(删除前要先切换到其他分支)
        git push origin --delete testBranch  :删除远程仓库的分支testBranch
    5.注意:在分支1上添加功能,当切换到另一个分支2(例如master分支),分支1上的代码是不会在分支2上显示的
    
#多任务多分支协作
        
    当当前项目并没有完成，但需要去做开发新的需求的时候。或者当前master指定的是线上的版本，需要做新的需求  
    的时候，但在做新需求的过程中，可能线上会出现BUG需要修复的时候，这种情况需要进行分支管理
    1.git branch 分支名称1branch1        :创建分支branch1
    2.git checkout 分支名称1             :切换到分支branch1
    3.在branch1分支上进行开发，但可能分支任务需要好几天完成，但每天都要提交代码到远程仓库
    4.git add .   
    5.git commit -m "描述"
    6.git push --set-upstream origin branch1  将branch1的代码提交到远程仓库

#同步远程仓库分支
    
    1.本地有新分支，远程仓库没有
        git add . 
        add commit -m "添加新分支"
        git push --set-upstream origin 新分支名称
    2.远程仓库有新分支，本地没有
        git branch 和git branch -a 查看本地分支和远程分支
        若没有发现远程分支，则使用git fetch会把远程服务器上所有的更新都拉取下来到本地仓库，然后继续执行
        git checkout -b 本地分支名 origin/远程分支名  :在本地创建本地分支(和远程分支名相同)，拉取远程分支到本地，并切换到该分支
        git pull origin 远程分支名  //拉取远程分支到本地
    3.本地删除了分支，远程也想删除。
        git branch -d 分支名        //删除本地分支
        git push origin -d 分支名   //删除远程分支
    4.远程删除了分支，本地也想删除
        git branch 查看本地分支 
        git branch -a 查看远程分支
        git remote show origin    //查看远程分支和本地分支的对应关系
        git remote prune origin   //删除远程已经删除过的分支



#⚠️如果拷贝本地项目A到项目B，项目B再重新提交到新的仓库,一定要先将B代码中的git管理删除(命令行: find ./ -name .git -exec rm -rf {} \;),然后重新提交到新的仓库

    1.git init 
    2.git remote add origin http://xxx/xxx.git
    3.git add .
    4.git commit -m "例如：创建新的项目"
    5.git push -u origin master
    
    
## 工作中命令总结
### 1. 当我们本地修改了代码,但是此时同事有新的代码提交到远程仓库了,需要我们及时将同事提交到远程仓库的代码拉取到我们本地的工作区,同时我们本地代码也没有进行add操作到暂存区时,此时我们git pull,会发现执行成功了,但是同事提交到远程仓库的代码我们并没有拉去成功,接下来该如何办?
    1. git stash   //先将我们本地修改的代码暂存起来,执行成功后,命令行中会返回类似下面的语句,说明保存成功了
    //执行git stash后:Saved working directory and index state WIP on master: 44c18d1 runtim
    2. git pull    //将远程仓库最新的代码拉去到本地,此时远程仓库的代码已经拉去到本地了
    3. git stash list  //查看我们临时保存的本地代码的列表
    //执行成功后: stash@{0}: WIP on master: 44c18d1 runtime
    //如果我们发现有多个类似 stash@{0} stash@{1} stash@{2} stash@{X}时,说明我们临时保存了多次本地代码,可以通过
    git stash show stash@{0} 来查看某次暂存的内容是什么
    4.git stash apply stash@{0}   //将我们pull之前暂存的本地代码修改内容恢复到当前工作区
    5.此时我们本地代码也已经恢复到我们pull之前的状态了,可以通过git status命令来查看是否是之前的状态
    6.但是如果遇到冲突的话,重新去打开工程的话,就打不开了,会提示说让去解决冲突
    7.来到项目WGFcodeNotes.xcodeproj,右键盘查看包内容,然后找到project.pbxproj并打开,然后全局搜索<<<<<<<或=======或>>>>>>>这就是冲突发生的标示,然后去解决冲突就OK了
    

### 2. 本地只有一个master分支，然后想撤销对上一次push到远程仓库的提交，即回退到指定的commitId
    localhost: baicai$ git log
    commit 98d79a2b006375c6d0e3af140355dc8bbcd96905 (HEAD->master,origin/master,origin/HEAD,checkWeekPwd)
    Author: baiaicaiai <wugong@baicai.com>
    Date:   Tue Jul 28 17:37:18 2020 +0800
        NXYS 2.3.2
    commit eb2cb5e27f0285e031828e79bb2249f4fb88a56e
    Author: baiaicaiai <wugong@baicai.com>
    Date:   Mon Jul 27 15:15:54 2020 +0800
        YKYG 2.2.3
    commit 6a76e3b3f2bc9def0dd2988095cdd9f9dc375acb
    Author: baiaicaiai <wugong@baicai.com>
    Date:   Fri Jul 24 16:46:06 2020 +0800
        2.3.1 1.1Version
#### 假如想回退到commitID: eb2cb5e27f0285e031828e79bb2249f4fb88a56e(YKYG 2.2.3),但是又可能这个最新的提交可能还会有用处，那么就先创建并切换一个新的分支（这样我们就将之前master分支代码copy到新的分支上了，以后要是需要的话可以从这个分支上取或者看就行了），然后提交到远程仓库，然后再切换到master分支，将master分支上的代码回滚到指定的commitID上，然后再提交到远程仓库就行了，提交过程会有错误提示，需要特别注意，这个地方需要强制更新到远程仓库，具体代码如下：
      git checkout -b checkWeekPwd  //创建并切换到新的分支上
      git push  //提交到远程仓库
      git checkout master   //切换到主分支上
      git reset --hard eb2cb5e27f0285e031828e79bb2249f4fb88a56e //将代码回滚到该commitID的版本
      git push  //提交远程仓库会报错
       ! [rejected]        master -> master (non-fast-forward)
      error: failed to push some refs to 'http://XXX.git'
      hint: Updates were rejected because the tip of your current branch is behind
      hint: its remote counterpart. Integrate the remote changes (e.g.
      hint: 'git pull ...') before pushing again.
      hint: See the 'Note about fast-forwards' in 'git push --help' for details.
      
      然后使用 进行强制更新到远程仓库就行了
      git push origin master --force
      
    
### 3. master主分支可能因为某些原因导致版本太低，需要将分支A作为新的master分支，那么就需要将master的本地和远程仓库中master都删除，然后再切换到新创建的master分支，再推送到远程仓库即可
    1.git checkout A        删除master分支前要先切换到分支A上
    2. git branch -D master  删除本地的master分支（如果用-d会提示删除不成功，需要-D来强制删除）
    3. git push origin -d master  //删除远程仓库的master分支，这里会报错
        error: src refspec master does not match any
        error: failed to push some refs to 'http://...XXX.git'
    4.原因是我们使用GitLab代码管理默认的保护分支是master分支，所以需要更改GitLab的设置，具体如下。  
        选择远程仓库 -> 最左边Setting -> Repository -> Default Branch ->选择指定的分支为master分支
    继续 git push origin -d master 
    报错：remote: GitLab: You can only delete protected branches using the web interface.  
        To http://...XXX.git
        ! [remote rejected] master (pre-receive hook declined)
        error: failed to push some refs to 'http://...XXX.git'
    原因：master分支是受保护的分支，所以需要在 Setting -> Repository -> Protected  
    Branches中设置不受保护,同时也可以设置操作的权限Maintainers/Developers
        
    继续 git push origin -d master 
        To http://...XXX.git
        - [deleted]         master
    删除成功
    5.在本地创建新的分支并取名为master分支
    git checkout -b master   在本地创建master分支并切换到master分支
    6. 将本地master分支推送到远程仓库
    git push origin master:master
    6.在GitLab中继续将master分支作为受保护的分支和默认的主分支即可

### 4. 远程仓库上的project忘了先做git pull，直接用之前的project版本的代码进行编写，突然想起忘了pull了，然后想用git pull来更新本地代码，结果报错，即新修改的代码，会被git服务器上的代码覆盖掉。由于我不想新修改的代码被覆盖，所以需要先保护现场：
    error: Your local changes to the following files would be overwritten by merge:
        WGFcodeNotes.xcodeproj/project.pbxproj
    Please commit your changes or stash them before you merge.

    解决方法
    1. git stash（储存现场）
    2. git pull origin master（拉取远程的master）
    3. git stash pop（恢复现场）
    4. 解决冲突
        
#### 5. 删除分支
#### 删除分支A，要先切换到其他分支，然后在执行如下命令
    1. 删除本地分支
    git branch -d A
    2. 删除远程分支
    git push origin --delete A

#### 6. 查看两个分支的区别
    1.显示出所有有差异的文件的详细差异
    git diff 分支A 分支B
    2.显示出所有有差异的文件列表
    git diff 分支A 分支B --stat
    3.显示指定文件的详细差异
    git diff Refund AppNameM 文件路径

#### 7. git reset 和git revert区别
#### 两者的作用都是撤销上一次commit操作
1. 本地代码 add -> commit 但是没有push

        git reset --soft|--mixed|--hard commitID
        --mixed 会保留源码，只是将 git commit 和 index 信息回退到了某个版本。
        --soft 保留源码，只回退到 commit 信息到某个版本.不涉及 index 的回退,如果还需要提交,直接 commit 即可。
        --hard 源码也会回退到某个版本, commit 和 index 都会回退到某个版本(注意，这种方式是改变本地代码仓库源码)。


2. 本地代码 add -> commit -> push 已经push到线上的远程仓库了

        git revert commitID 
        revert 之后你的本地代码会回滚到指定的历史版本,这时你再 git commit -> git push 就能把线上的代码也更新
        git revert是用一次新的commit来回滚之前的commit
#### 区别之处
* 如果你已经 push 到线上代码库，reset 删除指定commit 以后，你 git push 可能导致一大堆冲突，但是 revert 并不会。

* 如果在日后现有分支和历史分支需要合并的时候，reset 恢复部分的代码依然会出现在历史分支里，但是 revert 提交的 commit 并不会出现在历史分支里。

* reset 是在正常的 commit 历史中，删除了指定的 commit ，这时 HEAD 是向后移动了，而 revert 是在正常的 commit 历史中再 commit 一次，只不过是反向提交，他的 HEAD 是一直向前的。


#### 管理第三方库有一下三种方式
1. CocoaPods: Cocoapods会将所有的依赖库都放到另一个名为Pods的项目中，然后让主项目依赖Pods项目
2. Carthage: 自动将第三方框架编程为Dynamic framework(动态库)
3. SPM(swift packages manager): Swift构建系统集成在一起，可以自动执行依赖项的下载，编译和链接过程

                            CocoaPods                Carthage                  SPM
 
        适用语言              swift/OC                  swift/OC                swift

        是否兼容            兼容Carthage/SPM          兼容Carthage/SPM          兼容Carthage/SPM
        
        支持库数量           多，基本大部分都支持     大部分支持，但少于CocoaPods     大部分支持，但少于CocoaPods
        
        使用/配置复杂度            中                       高                       低
        
        项目入侵性               严重入侵                没有侵入性                   没有侵入性

        项目编译速度              慢                       快                         慢 
        
        源码可见                可见                     不可见                       可见


##  CocoaPods使用心得
### 1.[CocoaPods安装指南](https://guides.cocoapods.org/using/getting-started.html)
1. pod --version     :查看CocoaPods版本号
2. sudo gem install cocoapods       :更新 CocoaPods,只需再次安装 gem
3. sudo gem install cocoapods --pre         :更新CocoaPods预发布版本

### 2. CocoaPods使用
1. cd 到工程的根目录
2. touch Podfile 创建Podfile文件，注意必须是这个名字
3. open -a Xcode Podfile  打开Podfile文件进行编辑，

        #1.第一行要指定支持的平台和版本。
        platform :ios, '9.0'

        #忽略引入库的所有警告
        inhibit_all_warnings!


        #2.定义将它们链接到Xcode的目标，其实就是添加项目名称
        target 'AAA' do
          pod 'AFNetworking', '~> 4.0'
        end
4. 保存Podfile，然后pod install, pod install过程可能会失败多次，大部分是因为访问github时的网络问题

        Pod之前项目目录  
        AAA项目 ----【AAA AAA.xcodeproj】
        
        Pod install后项目目录
        AAA项目 ----【AAA AAA.xcodeproj Podfile Pods AAA.xcworkspace Podfile.lock】
5. 点击AAA.xcworkspace打开项目，可以发现和AAA并列的还有个Pods的工程，在AAA项目下还多出来了Pods和Frameworks两个文件夹
6. 在项目中创建XXX.pch文件，然后在里面导入第三方库如: #import <AFNetworking.h>,然后在Build Settings -> Prefix Header中设置pch文件的路径如:$(SRCROOT)/AAA/PrefixHeader.pch,然后就可以直接使用第三方库了

### 3. CocoaPods文件分析
#### 3.1Podfile: Podfile 是一种规范，用于描述一个或多个 Xcode 项目的目标的依赖关系
#### 3.2Podfile.lock: 当第一次运行**pod install**后，该文件就会自动生成，该文件记录了项目中使用CocoaPods的版本、第三方库的真实版本、来源和他们生成的哈希值。一般用在多人协作中，来确定版本是否被更改。这份文件中的第三方库的版本才是你项目中真实使用的版本，而不是Podfile文件中写的版本号；Podfile更像是一个版本约束，而Podfile.lock才是你真正使用的版本；如果让你去确定你使用某一个三方库的版本，你不应该找Podfile，而是应该找Podfile.lock文件。 即使你Podfile使用的定死版本的方式。

#### 为了整个团队第三方库的一致性，推荐将**Podfile.lock**文件加入到版本控制中；当A执行**pod install**后，podfile.lock文件中就会记录下当时最新Pods依赖库的版本，此时Bcheck下来这份包含podfile.lock文件的工程后，再去执行**pod install**后获取下来的Pods依赖库的版本就和最开始用户获取到的版本一致；若没有**podfile.lock**文件，后续团队所有成员都执行**pod install**后，都会获取最新版本的依赖库(可能执行install时机不一样，第三方库可能有新的版本)，有可能造成同一个团队使用的依赖库版本不一致


### 4. **pod install**和**pod update**区别
#### 很多人认为**pod install**是用在第一次使用CocoaPods去配置项目，而**pod update**是用在之后的更新配置中，这种想法是错误的
* pod install: 使用pod install在你的项目中安装新的库，即使你已经有了Podfile文件并且运行过pod install命令，或者你已经有添加、删除过库
* pod update: 仅仅是在你想更新库版本的时候
#### 4.1 **pod install**
1. 第一次在项目中获取第三方库时使用；每次对**Podfile**编辑时(添加/更新/删除)使用
2. 每次运行**pod install**后，都回去下载安装新的库，并且会修改**Podfile.lock**文件中记录的库的版本，**Podfile.lock**文件是用来追踪和锁定这些库的版本的
3. 运行**pod install**仅仅只能解决**Podfile.lock**中没有列出来的依赖关系，在**Podfile.lock**中列出的那些库，也仅仅只是去下载Podfile.lock中指定的版本，并不会去检查最新的版本
4. 没有在**Podfile.lock**中列出的那些库，会去检索Podfile中指定的版本

#### 4.2 **pod update**
1. 当运行**pod update 库名称**，CocoaPods将不会考虑**Podfile.lock**中列出的版本，而直接去查找该库的新版本。它将更新到这个库尽可能新的版本，只要符合**Podfile**中的版本限制要求。
2. 如果使用**pod update** 命令不带库名称参数，CocoaPods将会去更新**Podfile**中每一个库的尽可能新的版本。

#### 4.3 **pod outdated**
#### 当你使用**pod outdated**时，CocoaPods会罗列出所有在Podfile.lock中记录的有最新版本的库
#### 4.4 总结
1. 使用**pod update 库名称**可以去更新一个库的指定版本(检查相应的库是否存在更新的版本，并且更新)；而使用**pod install**将不会更新那些已经下载安装了的库
2. 当在Podfile文件中新增加一个库时，应该使用**pod install**而不是**pod update**,这样安装了新增的库，也不会重复安装已经存在的库。
3. 使用pod update仅仅只是去更新指定库的版本（或者全部库）
4. 必须将**Podfile.lcok**添加到版本控制提交中

### 5 什么时候用**pod install**？什么时候用**pod update**?
* 第一次使用cocoapod导入第三方库时，使用**pod install**
* 编辑**Podfile**文件，添加/删除/更新第三方库时使用**pod install**
* 有新的成员加入项目时，clone项目后，需要使用**pod install**去更新第三方库，如果用**pod update**会导致第三方库更新到最新的版本，这样和之前成员的第三方库版本就会不一样，导致冲突
* 检查哪些第三方库有最新的版本更新时，使用**pod outdated**
* 需要更新库版本时,使用**pod update 库名称**或者**pod update**

##  Carthage使用心得
## 1.安装
### 安装的前提是你本机已经安装好了`homebrew`,我们使用`brew`来进行安装
#### 1.首先我们先升级brew
#### `brew update` 需要很长时间,耐心等待吧
#### 2.`brew install carthage` 进行安装,安装完成后,会显示出你安装的Carthage的版本
#### 使用 `carthage version` 可以查看当前的版本 
#### 更新carthage版本：brew upgrade carthage
#### 删除carthage旧版本： brew cleanup carthage


## 2.使用
### 1.`touch Cartfile` 创建一个空的Cartfile文件
### 2.`open -a Xcode Cartfile` 打开Cartfile文件
### 3.在Github上找到需要的第三方库,例如`github "Alamofire/Alamofire" ~> 4.7`复制到Cartfile文件中
### 4.执行`carthage update`:更新包含了iOS/mac的库 `carthage update --platform iOS`: 更新了只包含iOS的库;或者 `carthage update --platform iOS --use-xcframeworks `使用最新的xcframeworks格式进行导入 第三方库已经导入到了,此时项目路径下会自动创建Carthage文件夹,更新完成后会出现checkout和Build两个文件夹(Carthage可以删除的,删除后相当于重新倒入第三方库,然后update即可)
### 5.导入第三方库(Alamofire)到项目中,在Target—>General->Frameworks, Libraries, and Embedded Content—>”+”—>add file —>选择/Carthage/Build下的第三方库即可 
## 3.创建桥接文件
### 1.New file-> Header File -> WGNoteBridgeHeader
### 2.在Build Setting -> Objective-C Bridging Header中添加桥接文件的路径,然后在桥接文件中y引入项目中用到的第三方文件
#import <Alamofire/Alamofire.h>

## 4.卸载
### 1. 执行`brew uninstall Carthage`
### ![avatar](/Users/apple/Desktop/WGLearnNote/ReadMePhoto/CarthageDelete1.png)
### 2. 如果要想删除本地所有版本的Carthage,执行`brew uninstall --force carthage`
### ![avatar](/Users/apple/Desktop/WGLearnNote/ReadMePhoto/CarthageDelete2.png)


## 5.遇到错误总结
###1.更新过程中遇到Could not find any available simulators for iOS,解决方案:升级carthage版本

## 6.常用操作
### 查看Carthage版本`carthage version`
### 升级Carthage版本`brew upgrade carthage`
### 创建空的Cartfile文件`touch Cartfile`
### 使用Xcode命令打开Cartfile文件`open -a Xcode Cartfile`
### 更新Cartfile文件中所有的第三方库`carthage update --platform iOS`
### 查看Carthage版本`carthage version`


## 7. 常见错误总结
### 7.1当我们想从版本0.36.0升级到0.37.0时，当执行brew upgrade carthage会遇到如下错误
        Error: 
          homebrew-core is a shallow clone.
        To `brew update`, first run:
          git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow
        This command may take a few minutes to run due to the large size of the repository.
        This restriction has been made on GitHub's request because updating shallow
        clones is an extremely expensive operation due to the tree layout and traffic of
        Homebrew/homebrew-core and Homebrew/homebrew-cask. We don't do this for you
        automatically to avoid repeatedly performing an expensive unshallow operation in
        CI systems (which should instead be fixed to not use shallow clones). Sorry for
        the inconvenience!
        Warning: carthage 0.36.0 already installed
### 按照提示我们执行git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow命令
        fatal: unable to access 'https://github.com/Homebrew/homebrew-core/': LibreSSL SSL_connect: 
        SSL_ERROR_SYSCALL in connection to github.com:443 
### 若遇到上面问题时，我们要打开手机热点，用电脑连接手机热点去更新下载最新的版本，然后继续执行git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow命令,遇到下面打印表示执行成功
        homebrew-core fetch --unshallow
        remote: Enumerating objects: 594107, done.
        remote: Counting objects: 100% (594062/594062), done.
        remote: Compressing objects: 100% (206094/206094), done.
        remote: Total 584546 (delta 381674), reused 578322 (delta 375600), pack-reused 
        Receiving objects: 100% (584546/584546), 227.15 MiB | 1.46 MiB/s, done.
        Resolving deltas: 100% (381674/381674), completed with 8459 local objects.
        From https://github.com/Homebrew/homebrew-core
           93cadf3457..a80f042079  master     -> origin/master

### 最后我们再执行brew upgrade carthage即可，然后通过carthage version查看是否升级到了最新版本0.37.0 

### 7.2 Xcode从Xcode12.1升级到Xcode12.3后，当更新第三方版本库时，执行carthage update --platform iOS，会遇到如下问题
        *** Cloning lottie-ios
        *** Cloning Kingfisher
        A shell task (/usr/bin/env git clone --bare --quiet https://github.com/onevcat/Kingfisher.git
        /Users/baicai/Library/Caches/org.carthage.CarthageKit/dependencies/Kingfisher) failed with 
        exit code 128:
        fatal: unable to access 'https://github.com/onevcat/Kingfisher.git/': LibreSSL SSL_connect: 
        SSL_ERROR_SYSCALL in connection to github.com:443 

### 暂时总结为就是访问GitHub上的第三方时的网络问题

### 7.3 从Xcode12.1升级到Xcode12.3后，我们开始使用如下命令即可管理第三方库
    carthage update --platform iOS --use-xcframeworks
    carthage update SnapKit --platform iOS --use-xcframeworks  指定更新某个库
### 这样在Carthage/Build下都是XXX.xcframework格式，直接在General->Frameworks、Libraries、and Embedded Content中添加第三方库(.xcframework格式)即可，不需要再Build Phases中再去添加Run Scrip项了，也不用再在里面写库路径了

### 当我们采用.xcframework格式后，模拟器运行没有问题，但是真机运行会报错
    dyld: launch, loading dependent libraries
    DYLD_LIBRARY_PATH=/usr/lib/system/introspection
    DYLD_INSERT_LIBRARIES=/Developer/usr/lib/libBacktraceRecording.dylib:/Developer/usr/lib/
    libMainThreadChecker.dylib:/Developer/Library/PrivateFrameworks/DTDDISupport.framework/
    libViewDebuggerSupport.dylib
### 解决方法就是在General->Frameworks、Libraries、and Embedded Content中将导入的第三方库后面的选项都选择为Embed&Sign选项即可

### 7.4 升级Xcode12.5 后报错，先到https://swift.org/download/#releases下载swift5.4的toolchain包，运行项目报如下错误
      module compiled with Swift 5.3.2 cannot be imported by the Swift 5.4 compiler:  
      /Users/baicai/Library/Developer/Xcode/DerivedData/NXY-bdiioyaaxczbxlgusvqtvlkagrqv/Build/Products/  
      Debug-iphoneos/SnapKit.framework/Modules/SnapKit.swiftmodule/arm64-apple-ios.swiftmodule
### 解决方法就是更新第三方库： carthage update --platform iOS --use-xcframeworks，这个过程比较扯淡，老是访问失败，只能慢慢尝试，多运行几次了，或者利用carthage update SnapKit --platform iOS --use-xcframeworks一个库一个库的更新接口，但是更新完成后运行项目又报如下错误
    <unknown>:0: error: module compiled with Swift 5.3.2 cannot be imported by the Swift 5.4 compiler:  
    /Users/baicai/Desktop/XXX.../XXX.framework  
    /Modules/XXX.swiftmodule/arm64-apple-ios.swiftmodule
#### ⚠️最好的方式就是删除项目目录下的Carthage和Cartfile.resolved文件，然后重新carthage update --platform iOS --use-xcframeworks，失败了就多重试几次；
#### ⚠️如果项目中有多个分支，切记要在主分支上进行更新第三方库，这样再切换到其他分支，就不需要重新更新第三方库了
#### 原因是XXX是我自定义的framework，所以也要对XXX所在的项目用Xcode12.5进行运行编译然后再合并模拟器和真机下的framework，然后保存在XXX/BaseFramework文件夹下
#### 合并真机SDK的流程如下：先选择XXX，然后分别选择真机和模拟器，在Xcode->XXX->Products下
Show in Finder，然后将真机和模拟器的XXX.framework保存下来，利用lipo -create 真机SDK 模拟器SDK -output /Users/baicai/Desktop/111111/XXX，将生成的XXX保存到桌面的111111文件夹下，然后将真机SDK中的XXX用111111文件下的XXX文件进行替换，将模拟器中的Modules/XXX.swiftmodule中内容拷贝到真机对应的Modules/XXX.swiftmodule文件中，但是模拟器中的Modules/XXX.swiftmodule/Project文件可以不用拷贝，然后直接将合并完成的真机SDK保存到XXX/BaseFramework文件夹下供其他项目使用

#### 升级Xcode16后 carthage出现各种问题并且太慢了 开始采用新的SPM来管理第三方库，但是SPM太慢了，开启ClashX Pro也不行，因为Xcode中的git是不会走代理的，方法就是在终端开启代理，先关闭Xcode
    git config --global http.proxy “http://127.0.0.1:7890” 
    git config --global https.proxy “http://127.0.0.1:7890”
    然后open -a Xcode.app打开Xcode即可
    取消代理
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    
