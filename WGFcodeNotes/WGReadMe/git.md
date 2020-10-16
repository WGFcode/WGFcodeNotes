# Git学习心得
## 一.配置
1. 在本地创建一个新的工程项目，项目名称:WGGitLearnProject，打开命令行，cd到该目录下 
2. git init                                                                              :初始化一个空的git仓库
3. git config --global user.name "baiaicaiai"                       :配置github的用户名称
4. git config --global user.emial "1813061716@qq.com"   :配置github的用户邮箱
5. git add .                                                                           :将本地项目添加到git的暂存区  
6. git commit -m "功能描述"                   :初始化本地项目并添加到git本地仓库" 
7. git remote add origin https://github.com/WGFcode/WGFcodeNotes.git   :初次添加到GitHub上需要和Github上的项目地址绑定
8. git push -u origin master                       :将项目推送的远程仓库
9. 如果是从仓库中拷贝代码到本地，在本地创建空的文件，然后使用git clone https://github.com/WGFcode/WGFcodeNotes.git 将远程仓库代码拷贝到本地创建的空文件中

#3. 命令行释意
#工作区

    1.git status            :查看当前工作区的状态，告诉你哪些文件被修改过
    2.git diff              :查看工程中被修改的内容
      git diff 文件1路径     :查看文件1被修改的内容
    3.git checkout .        :丢弃工作区文的所有文件修改
      git checkout -- 文件1路径  :若在工作区，即没有执行git add . 前，对本地工作区进行了修改，但想回退到没有修改前， 
      
#暂存区

    1.git add .          :将工作区的修改添加到暂存区
      git add 文件1路径    :将工作区的某一个文件的修改添加到咱存区
    2.git diff --cached   :查看暂存区和工作区的区别
      git diff --cached 文件1路径 :查看文件1的暂存区与工作区的区别
    3.git reset head 文件1路径 :将添加到暂存区的文件1回退到工作区，注意文件1中的修改代码在工作区还存在，只是文件1不在暂存区了，如果想丢弃工作区文件1的修改，继续使用git checkout -- 文件1路径即可
     git reset head  :将添加到暂存区的全部文件回退到工作区，代码依然存在，只是不再添加到暂存区了
#本地仓库

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
       git reset --hard 96954374b3e342c0c00e92648ed197015a5178d7将add UIButton版本回退到add ViewController View is Red Color的版本，此时工作区的代码都显示成了add ViewController View is Red Color版本时候的代码。如果想重新回到 add UIButton的版本，使用git reflog 
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
       在多人开发中，pull是为了本地commit和远程commit进行对比，如果有冲突，git会把这个冲突标记出来，这个时候需要先和最近一次push代码的人协商，解决冲突，然后在push，如果没有冲突git就直接将pull下来的代码和本地进行合并了，不会覆盖代码
       代码覆盖或者丢失：小白和小黑本地都是刚pull下来的代码，然后小白本地修改了代码，并且push到了远程(push1-push2),这时候小黑本地也修改了代码，但是没有commit,直接pull了小白的代码(push1-push2)到本地，此刻小黑的本地代码已经到push2了，然后小黑继续修改，如果修改了小白写过的代码文件white1，然后进行了commit&push到远程仓库push3,那么小白之前提交的white1文件就会被覆盖，所以多人开发一定要先commit,然后再pull,最后再push

#其它命令行分析

    1.git branch             :查看当前工程下的分支，当前分支前用*标记
    2.git branch XX          :创建XX的分支名称
    3.git checkout XX        :切换到XX分支上
    4.git checkout -b XX     :创建并切换到XX分支上，相当于12命令行
    5.创建分支testBranch完成功能后，先切换到主分支上
        git checkout -b testBranch   :创建并切换到分支testBranch上，完成部分功能开发后
        git add .    git commit -m "完成分支上功能的开发了"
        git checkout master   :切到主分支上
        git merge testBranch   :将testBranch分支合并到当前分支(master分支)
    6.完成分支合并后，就可以删除分支了
        git branch -d testBranch
    7.注意:在分支1上添加功能,当切换到另一个分支2(例如master分支),分支1上的代码是不会在分支2上显示的
#多任务多分支协作
        
    当当前项目并没有完成，但需要去做开发新的需求的时候。或者当前master指定的是线上的版本，需要做新的需求的时候，但在做新需求的过程中，可能线上会出现BUG需要修复的时候，这种情况需要进行分支管理
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
        若没有发现远程分支，则使用
        git fetch  远程主机的更新全部取回本地
        git checkout -b 本地分支名 origin/远程分支名  //在本地创建本地分支(和远程分支名相同)，拉取远程分支到本地，并切换到该分支
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
    //git stash show stash@{0} 来查看某次暂存的内容是什么
    4.git stash apply stash@{0}   //将我们pull之前暂存的本地代码修改内容恢复到当前工作区
    5.此时我们本地代码也已经恢复到我们pull之前的状态了,可以通过git status命令来查看是否是之前的状态
    6.但是如果遇到冲突的话,重新去打开工程的话,就打不开了,会提示说让去解决冲突
    7.来到项目WGFcodeNotes.xcodeproj,右键盘查看包内容,然后找到project.pbxproj并打开,然后全局搜索<<<<<<<或=======或>>>>>>>这就是冲突发生的标示,然后去解决冲突就OK了
    

### 2. 本地只有一个master分支，然后想撤销对上一次push到远程仓库的提交，即回退到指定的commitId
        localhost:NXYMerchantsProject baicai$ git log
        commit 98d79a2b006375c6d0e3af140355dc8bbcd96905 (HEAD -> master, origin/master, origin/HEAD, checkWeekPwd)
        Author: baiaicaiai <wugong@buybal.com>
        Date:   Tue Jul 28 17:37:18 2020 +0800
            NXYS 2.3.2
        commit eb2cb5e27f0285e031828e79bb2249f4fb88a56e
        Author: baiaicaiai <wugong@buybal.com>
        Date:   Mon Jul 27 15:15:54 2020 +0800
            YKYG 2.2.3
        commit 6a76e3b3f2bc9def0dd2988095cdd9f9dc375acb
        Author: baiaicaiai <wugong@buybal.com>
        Date:   Fri Jul 24 16:46:06 2020 +0800
            2.3.1 1.1Version
#### 假如想回退到commitID: eb2cb5e27f0285e031828e79bb2249f4fb88a56e(YKYG 2.2.3),但是又可能这个最新的提交可能还会有用处，那么就先创建并切换一个新的分支（这样我们就将之前master分支代码copy到新的分支上了，以后要是需要的话可以从这个分支上取或者看就行了），然后提交到远程仓库，然后再切换到master分支，将master分支上的代码回滚到指定的commitID上，然后再提交到远程仓库就行了，提交过程会有错误提示，需要特别注意，这个地方需要强制更新到远程仓库，具体代码如下：
      git checkout -b checkWeekPwd  //创建并切换到新的分支上
      git push  //提交到远程仓库
      git checkout master   //切换到主分支上
      git reset --hard eb2cb5e27f0285e031828e79bb2249f4fb88a56e //将代码回滚到该commitID的版本
      git push  //提交远程仓库会报错
       ! [rejected]        master -> master (non-fast-forward)
      error: failed to push some refs to 'http://192.168.1.242/iOS/nxy/NXYMerchantsProject.git'
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
            error: failed to push some refs to 'http://192.168.1.242/iOS/default/WLK.git'
        4.原因是我们使用GitLab代码管理默认的保护分支是master分支，所以需要更改GitLab的设置，具体如下。
            选择远程仓库 -> 最左边Setting -> Repository -> Default Branch ->选择指定的分支为master分支
        继续 git push origin -d master 
        报错：remote: GitLab: You can only delete protected branches using the web interface.
            To http://192.168.1.242/iOS/default/WLK.git
            ! [remote rejected] master (pre-receive hook declined)
            error: failed to push some refs to 'http://192.168.1.242/iOS/default/WLK.git'
        原因：master分支是受保护的分支，所以需要在 Setting -> Repository -> Protected Branches中设置不受保护,同时也可以设置操作的权限Maintainers/Developers
        
        继续 git push origin -d master 
            To http://192.168.1.242/iOS/default/WLK.git
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
    git diff Refund WLKM 文件路径
