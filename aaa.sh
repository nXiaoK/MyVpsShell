 @Override
    public BidStatusVo queryStatus(BidQueryStatus queryStatus) {
        Long projectId = projectService.findProjectIdByBdhBjbhZbid(queryStatus.getBjbh(), queryStatus.getBdh(), queryStatus.getZbid());
        if (projectId == null || projectId <= 0) {
            throw new RuntimeException("项目不存在");
        }
        List<SectionStatusVo> sectionStatusVos = evaluationResultService.selectSectionStatusVoListByProjectId(projectId);
        BidStatusVo bidStatusVo = new BidStatusVo();
        return bidStatusVo;
    }

    @Override
    public BidScoreVo queryByTkbm(BidScoreQuery scoreQuery) {
        Long projectId = projectService.findProjectIdByBdhBjbhZbid(scoreQuery.getBjbh(), scoreQuery.getBdh(), scoreQuery.getZbid());
        if (projectId == null || projectId <= 0) {
            throw new RuntimeException("项目不存在");
        }        if (StringUtils.isEmpty(bjbh)) {
                     return JGBAjaxResult.error("报建编号不能为空");
                 }
        EvaluationClause queryTkbm = new EvaluationClause();
        queryTkbm.setClauseCode(scoreQuery.getTkbm());
        EvaluationResult evaluationResult = evaluationResultService.selectEvaluationResultList(params).stream().findFirst().orElse(null);
        return null;
    }
dfafasfdfafdsfsf

    public JGBAjaxResult queryStatus(@RequestBody BidQueryStatus queryStatus) {
        JGBAjaxResult valid = validateBaseParams(queryStatus.getBdh(), queryStatus.getBjbh(), queryStatus.getZbid());
        if (valid != null) {
            return valid;
        }
        if (StringUtils.isEmpty(bjbh)) {
            return JGBAjaxResult.error("报建编号不能为空");
        }
        BidStatusVo vo = bidExternalInterfaceService.queryStatus(queryStatus);
        return successOrFail(vo);
    }

    @Override
    public BidScoreDetailVo query(BidScoreQuery scoreQuery) {
        Long projectId = projectService.findProjectIdByBdhBjbhZbid(scoreQuery.getBjbh(), scoreQuery.getBdh(), scoreQuery.getZbid());
        if (projectId == null || projectId <= 0) {
            throw new RuntimeException("项目不存在");
        }
        List<ScoreDetail> scoreDetails = evaluationResultService.selectScoreDetailListByProjectId(projectId);
        BidScoreDetailVo detailVo = new BidScoreDetailVo();
        BeanUtils.copyProperties(scoreQuery, detailVo);
        detailVo.setScoreDetails(scoreDetails);
        detailVo.setTimestamp(DateUtils.getNowDate().getTime());
        return detailVo;
    }
